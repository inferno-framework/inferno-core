require 'English'
require 'yaml'
require_relative 'session/create_session'
require_relative 'session/start_run'
require_relative 'session/cancel_run'
require_relative 'session/session_status'
require_relative 'session/session_results'
require_relative 'session/session_compare'
require_relative 'session/session_details'

module Inferno
  module CLI
    # Orchestrates multi-session Inferno test runs from a YAML configuration file.
    #
    # YAML format:
    #
    #   comparison_config:                         # optional
    #     normalized_strings:                      # optional; global normalization rules applied to
    #       - "http://my-server.example.com"       # both expected and actual before comparing.
    #       - "http://other-value.example.com"     # plain string: replaced with <NORMALIZED>;
    #                                              # URL-encoded form is also replaced automatically.
    #       - "/code_challenge=[A-Za-z0-9+\\/=_-]{20,}/"  # regex string (wrapped in /…/): compiled
    #                                              # to a Regexp and replaced with <NORMALIZED>.
    #                                              # Supports flags: /pattern/i, /pattern/m, etc.
    #                                              # URL-encoded form is NOT auto-replaced for regex.
    #       - pattern: '/code_challenge=[A-Za-z0-9+\\/=_-]{20,}/'  # hash form: use when you need
    #         replacement: '<CODE_CHALLENGE>'      # a named placeholder instead of <NORMALIZED>.
    #       - patterns:                            # 'patterns' (plural) shares one replacement
    #           - '/code_challenge=[A-Za-z0-9+\\/=_-]{20,}/'  # across multiple patterns.
    #           - '/code_verifier=[A-Za-z0-9+\\/=_-]{20,}/'
    #         replacement: '<PKCE_VALUE>'
    #
    #     # Single-session scripts: expected file config lives directly under comparison_config.
    #     expected_results_file: expected.json     # optional; relative to yaml file; defaults to
    #                                              #   <yaml basename>_expected.json
    #     alternate_expected_files:                # optional; tried in order; first matching wins
    #       - file: alt_expected.json              # required; relative to yaml file
    #         when:                                # required; all conditions must match (AND logic)
    #           - field: inputs.url                # required: can be inputs.<name>, configuration_messages,
    #                                              #   or inferno_base_url
    #             matches: ^http://                # other values are top-level session detail fields.
    #                                              # Evaluated against GET api/test_sessions/{id}.
    #
    #     # Multi-session scripts: per-session config is nested under sessions.<name>.
    #     sessions:
    #       my_name:                               # matches session name key (sessions[*].name or suite)
    #         expected_results_file: expected.json # optional; defaults to <yaml basename>_<name>_expected.json
    #         alternate_expected_files:            # optional; same structure as single-session above
    #           - file: alt_expected.json
    #             when:
    #               - field: inputs.url
    #                 matches: ^http://
    #
    #   sessions:
    #     - suite: my_suite                        # internal ID, title, or short title
    #       name: my_name                          # optional; used as key in multi-session
    #       preset: my-preset                      # optional; internal ID or title
    #       suite_options:                         # optional; option_key and option_value can be the
    #         option_key: option_value             #           internal values or the displayed titles
    #
    #   steps:
    #     - status: created|done|waiting           # required; other status values cannot be matched on
    #       last_completed: ""                     # optional; required unless the status is created
    #                                              #           can be a full ID, short ID (e.g. "1.01"), or 'suite'
    #       session: my_name                       # optional; required when multiple sessions to indicate which session
    #                                              #           can match this step
    #       action: end_script|noop|wait           # optional; built-in action
    #                                              #           (mutually exclusive with command/start_run)
    #       # OR
    #       command: "bundle exec ..."             # optional; arbitrary shell command (requires
    #                                              #           --allow-commands CLI flag)
    #       # OR
    #       start_run:
    #         session: "{session_id}"              # optional; defaults to current session
    #         runnable: "1.01"                     # required; can be a short id from the UI,
    #                                              #           an internal long id, or 'suite'
    #         inputs:                              # optional; the key must be the internal name
    #           input_name: "value"                #           for the input
    #           input_name: "@path/to/file.txt"    #           prefix value with @ to read from a file;
    #                                              #           relative paths are resolved from the
    #                                              #           directory containing this script file
    #       timeout: 300                           # optional; seconds to wait for next match (Default is 120)
    #       next_poll_session: other_name          # optional; switch polling target after command
    #       state_description: "..."               # optional; logged when step is matched
    #       action_description: "..."              # optional; logged when step is matched
    #
    # Built-in action values:
    #   END_SCRIPT  — terminate script successfully
    #   NOOP        — no-op; keep polling with (optionally updated) timeout or session
    #   WAIT        — keep polling without breaking out of the current poll loop
    #                 (unlike noop, does not restart the loop with a new timeout or session)
    #
    # Security note:
    #   Steps using command: execute arbitrary shell commands via the system() call. This is
    #   intentional for use cases like browser automation (e.g. Selenium) that must interact
    #   with Inferno's waiting state mid-test. Because of this risk, command: steps are blocked
    #   by default and require the --allow-commands CLI flag to run. Scripts that contain no
    #   command: steps are unaffected and do not need the flag.
    #
    # Template tokens in command strings and start_run input values:
    #   {session_id}              — current session's Inferno session ID
    #   {NAME.session_id}         — named session's ID
    #   {result_message}          — current session's wait_result_message (shell-quoted)
    #   {NAME.result_message}     — named session's wait_result_message (shell-quoted)
    #   {wait_outputs.KEY}        — current session's wait output by name (shell-quoted)
    #   {NAME.wait_outputs.KEY}   — named session's wait output by name (shell-quoted)
    #   {inferno_base_url}        — the Inferno base URL (--inferno-base-url option)
    class ExecuteScript
      SHORT_ID_PATTERN = /\A[0-9][0-9.]*\z/

      ScriptSession = Struct.new(
        :key, :suite_id, :session_id, :short_id_map,
        keyword_init: true
      )

      ExecutionStatus = Struct.new(
        :done, :failed, :current_session, :current_timeout, :last_log_time,
        :cross_session_status, :last_step_signatures
      )

      attr_accessor :yaml_file, :options, :execution_status

      def initialize(yaml_file, options)
        self.yaml_file = yaml_file
        self.options = options
        validate_yaml_file!
        self.execution_status = ExecutionStatus.new(
          done: false,
          failed: false,
          current_session: sessions.first,
          current_timeout: options[:default_poll_timeout],
          cross_session_status: {},
          last_step_signatures: {}
        )
      end

      def run
        exit(orchestrate)
      end

      private

      def script_config
        @script_config ||= YAML.safe_load_file(File.expand_path(yaml_file))
      end

      def sessions
        @sessions ||= create_sessions
      end

      def session_name_to_id_map
        @session_name_to_id_map ||= sessions.to_h { |session| [session.key, session.session_id] }
      end

      def steps
        @steps ||= scripted_steps || []
      end

      def multi_session_script?
        script_config['sessions'].present? &&
          (script_config['sessions'].length > 1)
      end

      def yaml_directory
        @yaml_directory ||= File.dirname(File.expand_path(yaml_file))
      end

      def yaml_basename
        @yaml_basename ||= File.basename(yaml_file, '.yaml')
      end

      def validate_yaml_file!
        unless File.exist?(yaml_file)
          puts JSON.pretty_generate({ errors: "File not found: #{yaml_file}" })
          exit(1)
        end
        return if yaml_file.end_with?('.yaml', '.yml')

        puts JSON.pretty_generate(
          { errors: "'#{yaml_file}' does not appear to be a YAML file (.yaml or .yml extension required)." }
        )
        exit(1)
      end

      # ---------------------------------------------------------------------------
      # Session creation
      # ---------------------------------------------------------------------------

      def create_sessions
        script_config['sessions']&.map do |session_config|
          create_session_from_config(session_config)
        end
      end

      def create_session_from_config(session_config)
        suite = session_config['suite']
        warn "Creating '#{suite}' session..."
        creator = Session::CreateSession.new(suite, session_create_options(session_config))
        session_details = creator.create_session
        key = session_config['name'] || suite
        warn "Session created: #{session_details['id']}"
        ScriptSession.new(
          key: key,
          suite_id: session_details['test_suite_id'],
          session_id: session_details['id'],
          short_id_map: extract_short_ids_from_session_details(session_details)
        )
      end

      def session_create_options(session_config)
        {
          preset: session_config['preset'],
          suite_options: session_config['suite_options'],
          inferno_base_url: options[:inferno_base_url]
        }
      end

      def extract_short_ids_from_session_details(session_details)
        results = {}
        results['suite'] = session_details['test_suite_id']
        suite_details = session_details['test_suite']
        suite_details['test_groups']&.each do |group|
          extract_short_ids(group, results)
        end
        suite_details['tests']&.each do |test|
          extract_short_ids(test, results)
        end

        results
      end

      # Recursive runnable walk collecting { short_id => full_id } pairs.
      def extract_short_ids(runnable, results)
        results[runnable['short_id']] = runnable['id'] if runnable['short_id'] && runnable['id']
        runnable['test_groups']&.each do |group|
          extract_short_ids(group, results)
        end
        runnable['tests']&.each do |test|
          extract_short_ids(test, results)
        end
      end

      # ---------------------------------------------------------------------------
      # Extract Steps - resolve short ids in the last_completed entries
      # ---------------------------------------------------------------------------

      def scripted_steps
        script_config['steps']&.map do |step|
          last_completed = step['last_completed'].to_s
          next step unless last_completed.match?(SHORT_ID_PATTERN) || last_completed == 'suite'

          resolved_test_id = resolve_short_id(last_completed, step['session'])
          warn "Resolved short ID \"#{last_completed}\" -> \"#{resolved_test_id}\""
          step.merge('last_completed' => resolved_test_id)
        end
      end

      def resolve_short_id(short_id, session_name)
        if multi_session_script? && session_name.blank?
          puts JSON.pretty_generate(
            {
              errors: "Short ID '#{short_id}' used in step 'last_completed' " \
                      "without a 'session' in a multi-session script."
            }
          )
          exit(3)
        end

        target_session = session_for_name(session_name)
        test_id = target_session&.short_id_map&.dig(short_id)
        unless test_id
          puts JSON.pretty_generate(
            { errors: "Short ID '#{short_id}' not found in session '#{target_session.key}'" }
          )
          exit(3)
        end
        test_id
      end

      def session_for_name(session_name)
        if session_name.present?
          sessions.find { |session| session.key == session_name }
        else
          sessions.first
        end
      end

      # ---------------------------------------------------------------------------
      # Orchestration loop
      # ---------------------------------------------------------------------------

      def orchestrate
        loop do
          matched_step = poll_for_next_step
          execution_status.done = true if [nil, 'END_SCRIPT'].include?(matched_step[:command])
          break if execution_status.done

          take_step(matched_step)
          break if execution_status.done
        end

        warn ''
        warn "All runs complete #{execution_status.failed ? 'with errors' : 'successfully'}."

        if results_match_expected?(sessions)
          execution_status.failed ? 3 : 0
        else
          3
        end
      end

      # perform the specified command to continue the script
      def take_step(matched_step)
        execution_status.current_timeout = next_step_timeout(matched_step)
        if matched_step[:next_poll_session].present?
          execution_status.current_session = session_for_name(matched_step[:next_poll_session])
        end
        return if matched_step[:command] == 'NOOP'

        if matched_step[:command] == 'START_RUN'
          target_session_id = start_run_target_session(matched_step[:start_run])
          warn "Executing: #{start_run_description(matched_step[:start_run], session_id: target_session_id)}"
          execute_start_run(matched_step[:start_run], target_session_id)
        else
          warn "Executing: #{matched_step[:command]}"
          execution_status.failed = true unless execute_command(matched_step[:command])
          execution_status.done = execution_status.failed
        end
      end

      def next_step_timeout(matched_step)
        matched_step[:timeout].present? ? matched_step[:timeout] : options[:default_poll_timeout]
      end

      def start_run_target_session(start_run_details)
        if start_run_details['session'].present?
          if session_name_to_id_map[start_run_details['session']].present?
            session_name_to_id_map[start_run_details['session']]
          else
            start_run_details['session']
          end
        elsif multi_session_script?
          puts JSON.pretty_generate({ errors: 'Start run steps must have `session` defined when multiple sessions.' })
          exit(3)
        else
          execution_status.current_session.session_id
        end
      end

      # templates already resolved
      def execute_start_run(start_run_config, target_session_id)
        start_run_options = {
          runnable: start_run_config['runnable'],
          inputs: start_run_config['inputs'],
          inferno_base_url: options[:inferno_base_url]
        }

        runner = Session::StartRun.new(target_session_id, start_run_options)
        runner.start_run
      end

      # ---------------------------------------------------------------------------
      # Polling
      # ---------------------------------------------------------------------------

      def poll_for_next_step
        session = execution_status.current_session
        timeout = execution_status.current_timeout

        warn ''
        warn "Polling session: #{session.key} (#{session.session_id}) timeout=#{timeout}s"
        deadline = Time.now + timeout
        execution_status.last_log_time = Time.now - 30 # ensure first active-status line is logged immediately

        loop do
          status = fetch_session_status(session.session_id)
          run_status = status['status']

          case run_status
          when 'running', 'queued', 'cancelling'
            log_poll_if_needed(status, session.key)
          when 'waiting', 'done', 'created'
            execution_status.cross_session_status = {} # reset per poll cycle
            execution_status.cross_session_status[session.key] = status
            result = handle_actionable_status(status, session, timeout)
            return result if result
          end

          if Time.now >= deadline
            warn "Timeout after #{timeout}s: session=#{session.key} status=#{run_status}"
            execution_status.failed = true
            return { command: nil, timeout: timeout, next_poll_session: nil }
          end

          sleep options[:poll_interval]
        end
      end

      # Returns a step hash to act on, or nil to keep polling.
      def handle_actionable_status(status, session, timeout)
        run_status = status['status']
        matched_step = match_step(status, session.key)

        if matched_step
          return nil if matched_step[:command] == 'WAIT'

          return verify_step(matched_step, status, session, timeout)
        elsif run_status == 'waiting'
          last_completed = format_last_completed(last_completed_from_status(status), session.key)
          warn "UNHANDLED WAIT - Canceling: session=#{session.key} last_completed=#{last_completed}"
          execution_status.failed = true
          attempt_cancel(session.session_id, status)
        else
          last_completed = format_last_completed(last_completed_from_status(status), session.key)
          warn "UNMATCHED: session=#{session.key} status=#{run_status} last_completed=#{last_completed}"
          execution_status.failed = true
          return { command: nil, timeout: timeout, next_poll_session: nil }
        end

        nil
      end

      # Checks for a repeated steps that aren't NOOPs; returns nil to keep polling or the step to act on.
      def verify_step(matched_step, status, session, timeout)
        run_status = status['status']
        last_completed = last_completed_from_status(status)
        step_sig = [run_status, last_completed]

        if step_sig == execution_status.last_step_signatures[session.key] && matched_step[:command] != 'NOOP'
          execution_status.failed = true
          if run_status == 'waiting'
            warn "Loop detected - Canceling: session=#{session.key} last_completed=#{last_completed}"
            attempt_cancel(session.session_id, status)
            return nil
          else
            warn "Loop detected: session=#{session.key} status=#{run_status} " \
                 "last_completed=#{last_completed}"
            return { command: nil, timeout: timeout, next_poll_session: nil }
          end
        end

        execution_status.last_step_signatures[session.key] = step_sig
        matched_step
      end

      def log_poll_if_needed(status, session_key)
        return unless Time.now - execution_status.last_log_time >= 30

        last_completed = last_completed_from_status(status)
        poll_status_last_test =
          last_completed.present? ? " - last test: #{format_last_completed(last_completed, session_key)}" : ''
        warn "  [#{session_key}] #{status['status']}#{poll_status_last_test}"
        execution_status.last_log_time = Time.now
      end

      def fetch_session_status(session_id)
        Session::SessionStatus.new(session_id, options).status_for_session
      end

      def attempt_cancel(session_id, status)
        Session::CancelRun.new(session_id, options).cancel_run(status)
      end

      # ---------------------------------------------------------------------------
      # Step matching
      # ---------------------------------------------------------------------------

      def match_step(status, session_key)
        run_status = status['status']
        last_completed = last_completed_from_status(status)

        matched = find_matching_step(run_status, last_completed, session_key)
        return nil unless matched

        log_matched_rule(matched, last_completed, session_key)
        step_details = resolve_command(matched, status, session_key)
        step_details[:timeout] = matched['timeout'].to_i if matched['timeout'].present?
        step_details[:next_poll_session] = matched['next_poll_session'] if matched['next_poll_session'].present?

        step_details
      end

      # when status['status'] is done, return the executed runnable that was completed
      # otherwise, return last_test_executed
      def last_completed_from_status(status)
        if status['status'] == 'done'
          (status['test_id'] || status['test_group_id'] || status['test_suite_id']).to_s
        else
          status['last_test_executed'].to_s
        end
      end

      def log_matched_rule(matched, last_completed, session_key)
        warn 'Matched rule:'
        warn "  State: #{matched['state_description']}" if matched['state_description'].present?
        warn "  status=#{matched['status']} last_completed=#{format_last_completed(last_completed, session_key)}"
        warn "  Command: #{step_command_description(matched)}"
        matched_rule_optional_lines(matched)
      end

      def matched_rule_optional_lines(matched)
        warn "  Action: #{matched['action_description']}" if matched['action_description'].present?
        warn "  Next poll session: #{matched['next_poll_session']}" if matched['next_poll_session'].present?
        warn "  Timeout: #{matched['timeout']}" if matched['timeout'].present?
      end

      def format_last_completed(last_completed, session_key)
        return '(none)' if last_completed.empty?

        short_id = session_for_name(session_key)&.short_id_map&.key(last_completed)
        short_id ? "#{last_completed} (#{short_id})" : last_completed
      end

      def find_matching_step(run_status, last_completed, session_key)
        steps.find do |step|
          step['status'] == run_status &&
            step['last_completed'].to_s == last_completed &&
            (step['session'].blank? || step['session'] == session_key)
        end
      end

      # ---------------------------------------------------------------------------
      # Command resolution
      # ---------------------------------------------------------------------------

      # Returns a human-readable description of the step's command for logging.
      def step_command_description(step)
        if step.key?('start_run')
          start_run_description(step['start_run'] || {})
        elsif step.key?('action')
          "action: #{step['action']}"
        else
          step['command'].to_s
        end
      end

      def start_run_description(start_run_details, session_id: nil)
        session_token =
          if session_id.present?
            session_id
          elsif start_run_details['session'].present?
            "{#{start_run_details['session']}.session_id}"
          else
            '{session_id}'
          end
        runnable_token = start_run_details['runnable'].present? ? " '#{start_run_details['runnable']}'" : ''
        parts = ["bundle exec inferno session start_run '#{session_token}'#{runnable_token}"]
        if start_run_details['inputs'].present?
          parts << "-i #{start_run_details['inputs'].map do |k, v|
            "#{k}:#{v}"
          end.join(' ')}"
        end
        parts.join(' ')
      end

      def resolve_command(step, status, session_key)
        if step.key?('start_run')
          start_run = apply_templates_to_start_run(step['start_run'] || {}, status, session_key)
          { command: 'START_RUN', start_run: }
        elsif step.key?('action')
          { command: step['action'].upcase }
        else
          cmd = step['command'].to_s
          { command: cmd.include?('{') ? apply_templates(cmd, status, session_key) : cmd }
        end
      end

      # ---------------------------------------------------------------------------
      # Template token substitution
      # ---------------------------------------------------------------------------

      # Substitutes all {token} placeholders in +str+.
      # Cross-session tokens trigger an on-demand status fetch (cached in
      # execution_status.cross_session_status, reset each poll cycle in poll_for_next_step).
      #
      # Returns the resolved string or exits 3 if a token cannot be resolved.
      def apply_templates(str, status, session_key)
        result = str.dup

        # {inferno_base_url} — the Inferno base URL
        result.gsub!('{inferno_base_url}') { options[:inferno_base_url] }

        # {session_id} — current session
        result.gsub!('{session_id}') { session_name_to_id_map[session_key] }

        # {NAME.session_id} — named session
        result.gsub!(/\{([^}.]+)\.session_id\}/) do
          name = Regexp.last_match(1)
          id   = session_name_to_id_map[name]
          unless id
            puts JSON.pretty_generate({ errors: "Unknown session name '#{name}' in token {#{name}.session_id}" })
            exit(3)
          end
          id
        end

        # {result_message} — current session wait result message
        result.gsub!('{result_message}') do
          msg = status['wait_result_message']
          unless msg
            puts JSON.pretty_generate({ errors: 'Token {result_message} used but session is not in waiting state' })
            exit(3)
          end
          msg
        end

        # {NAME.result_message} — another session's wait result message
        result.gsub!(/\{([^}.]+)\.result_message\}/) do
          name       = Regexp.last_match(1)
          other_stat = cross_session_status(name)
          msg        = other_stat['wait_result_message']
          unless msg
            puts JSON.pretty_generate(
              { errors: "Token {#{name}.result_message} used but session '#{name}' is not in waiting state" }
            )
            exit(3)
          end
          msg
        end

        # {wait_outputs.KEY} — current session wait output
        result.gsub!(/\{wait_outputs\.([^}]+)\}/) do
          key    = Regexp.last_match(1)
          output = find_wait_output(status['wait_outputs'], key)
          unless output
            puts JSON.pretty_generate({ errors: "Wait output '#{key}' not found in current session" })
            exit(3)
          end
          output
        end

        # {NAME.wait_outputs.KEY} — another session's wait output
        result.gsub!(/\{([^}.]+)\.wait_outputs\.([^}]+)\}/) do
          name       = Regexp.last_match(1)
          key        = Regexp.last_match(2)
          other_stat = cross_session_status(name)
          output     = find_wait_output(other_stat['wait_outputs'], key)
          unless output
            puts JSON.pretty_generate(
              { errors: "Wait output '#{key}' not found in session '#{name}'" }
            )
            exit(3)
          end
          output
        end

        result
      end

      def find_wait_output(wait_outputs, key)
        Array(wait_outputs).find { |o| o['name'] == key }&.dig('value')
      end

      # Returns the cached enriched status for a named session, fetching it on
      # first access within a poll cycle.
      def cross_session_status(name)
        execution_status.cross_session_status[name] ||= begin
          session_id = session_name_to_id_map[name]
          unless session_id
            puts JSON.pretty_generate({ errors: "Unknown session name '#{name}'" })
            exit(3)
          end
          fetch_session_status(session_id)
        end
      end

      def apply_templates_to_start_run(start_run, status, session_key)
        if start_run['session'].present?
          start_run['session'] = apply_templates(start_run['session'], status, session_key)
        end
        start_run['inputs']&.each_key do |input_name|
          raw = start_run['inputs'][input_name]
          raw = raw.to_json if raw.is_a?(Array) || raw.is_a?(Hash)
          value = apply_templates(raw.to_s, status, session_key)
          start_run['inputs'][input_name] = expand_file_input_path(value)
        end

        start_run
      end

      def expand_file_input_path(value)
        return value unless value.start_with?('@')

        path = value[1..]
        return value if Pathname.new(path).absolute?

        "@#{File.expand_path(path, File.dirname(yaml_file))}"
      end

      # ---------------------------------------------------------------------------
      # Command execution
      # ---------------------------------------------------------------------------

      def execute_command(cmd)
        unless options[:allow_commands]
          warn "Error: script contains a 'command' step but --allow-commands was not set."
          warn "  command: #{cmd}"
          warn 'Re-run with --allow-commands to permit arbitrary shell command execution.'
          return false
        end

        system(cmd)
        $CHILD_STATUS.success?
      end

      # ---------------------------------------------------------------------------
      # check results
      # ---------------------------------------------------------------------------

      def results_match_expected?(sessions)
        sessions.map do |session|
          warn "Checking results for #{session.key} session (#{session.session_id})"
          warn "  View session at #{session_display_url(session)}"

          if any_error_results?(session)
            warn '  Session contained execution errors - skipping comparison'
            false
          else
            compare_session(session)
          end
        end.all?
      end

      def session_display_url(session)
        base_url = (options[:inferno_base_url].presence || Inferno::Application['base_url']).to_s.delete_suffix('/')
        "#{base_url}/#{session.suite_id}/#{session.session_id}"
      end

      def any_error_results?(session)
        results = Session::SessionResults.new(session.session_id, options).results_for_session(session.session_id)
        results.any? { |result| result['result'] == 'error' }
      end

      # ---------------------------------------------------------------------------
      # Compare / save results
      # ---------------------------------------------------------------------------

      def resolve_expected_file(key)
        session_cfg = comparison_session_config(key)
        if session_cfg['expected_results_file'].present?
          File.expand_path(session_cfg['expected_results_file'], yaml_directory)
        elsif multi_session_script?
          File.join(yaml_directory, "#{yaml_basename}_#{key}_expected.json")
        else
          File.join(yaml_directory, "#{yaml_basename}_expected.json")
        end
      end

      def comparison_session_config(key)
        if multi_session_script?
          (comparison_config['sessions'] || {})[key] || {}
        else
          comparison_config
        end
      end

      def compare_session(session)
        expected_file = resolve_expected_file_for_comparison(session)

        if File.exist?(expected_file)
          cmp = Session::SessionCompare.new(session.session_id, compare_options(expected_file))
          matched = cmp.results_match?
          warn "  Comparing against #{File.basename(expected_file)}"
          warn "  Actual results matched expected results? #{matched}"
          unless matched
            cmp.save_actual_results_to_file
            cmp.save_comparison_csv_to_file
          end
          matched
        else
          warn "  Expected results file not found; writing actual results to #{expected_file}"
          results = Session::SessionResults.new(session.session_id, options).results_for_session(session.session_id)
          File.write(expected_file, results.to_json)
          false
        end
      end

      def resolve_expected_file_for_comparison(session)
        default_file = resolve_expected_file(session.key)
        alternates = Array(comparison_session_config(session.key)['alternate_expected_files'])
        return default_file if alternates.empty?

        session_details = Session::SessionDetails.new(session.session_id, options).details_for_session

        alternates.each do |alt|
          conditions = Array(alt['when'])
          next if conditions.empty?
          next unless conditions.all? { |cond| session_detail_condition_matches?(cond, session_details) }

          file = File.expand_path(alt['file'], yaml_directory)
          return file
        end

        default_file
      end

      def session_detail_condition_matches?(condition, session_details)
        return false unless condition_has_field_and_pattern?(condition)

        field = condition['field']
        matches_pattern = condition['matches']
        not_matches_pattern = condition['not_matches']
        test_suite = session_details['test_suite'] || {}

        if field == 'configuration_messages'
          configuration_messages_match?(test_suite, matches_pattern, not_matches_pattern)
        elsif field == 'inferno_base_url'
          string_matches?(options[:inferno_base_url].to_s, matches_pattern, not_matches_pattern)
        elsif field.start_with?('inputs.')
          input_name = field.delete_prefix('inputs.')
          test_suite_input_matches?(test_suite, input_name, matches_pattern, not_matches_pattern)
        else
          false
        end
      end

      def condition_has_field_and_pattern?(condition)
        condition['field'].present? && (condition['matches'].present? || condition['not_matches'].present?)
      end

      def string_matches?(value, matches_pattern, not_matches_pattern)
        return false if matches_pattern && !Regexp.new(matches_pattern).match?(value)
        return false if not_matches_pattern && Regexp.new(not_matches_pattern).match?(value)

        true
      end

      def configuration_messages_match?(test_suite, matches_pattern, not_matches_pattern)
        messages = Array(test_suite['configuration_messages'])
        if matches_pattern && messages.none? { |msg| Regexp.new(matches_pattern).match?(msg['message'].to_s) }
          return false
        end
        if not_matches_pattern && messages.any? { |msg| Regexp.new(not_matches_pattern).match?(msg['message'].to_s) }
          return false
        end

        true
      end

      def test_suite_input_matches?(test_suite, input_name, matches_pattern, not_matches_pattern)
        value = Array(test_suite['inputs']).find { |i| i['name'] == input_name }&.dig('value')
        string_matches?(value.to_s, matches_pattern, not_matches_pattern)
      end

      def comparison_config
        @comparison_config ||= script_config['comparison_config'] || {}
      end

      def compare_options(expected_file)
        {
          expected_results_file: expected_file,
          compare_messages: options[:compare_messages],
          compare_result_message: options[:compare_result_message],
          inferno_base_url: options[:inferno_base_url],
          normalized_strings: Array(comparison_config['normalized_strings'])
        }
      end
    end
  end
end
