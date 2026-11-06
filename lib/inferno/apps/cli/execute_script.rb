require 'English'
require 'yaml'
require_relative 'session/create_session'
require_relative 'session/start_run'
require_relative 'session/cancel_run'
require_relative 'session/session_status'
require_relative 'session/session_results'
require_relative 'session/session_compare'
require_relative 'session/session_details'
require_relative 'session/session_data'

module Inferno
  module CLI
    # Orchestrates multi-session Inferno test runs from a YAML configuration file.
    #
    # YAML format:
    #
    #   sessions:                                  # Controls the creation of Inferno sessions for the execution
    #                                              #   a session for each indicated suite will be created and
    #                                              #   a successful run will have the expected results for all sessions.
    #     - suite: my_suite                        # internal ID, title, or short title
    #       name: my_name                          # required (and unique) in multi-session scripts, optional
    #                                              #           otherwise; must not contain whitespace, '.', '{', or '}'
    #       preset: my-preset                      # optional; internal ID or title
    #       suite_options:                         # optional; option_key and option_value can be the
    #         option_key: option_value             #           internal values or the displayed titles
    #
    #
    #   comparison_config:                         # optional; Controls the comparison of actual results during a run
    #                                              #    to the expected results for each created Inferno session.
    #                                              #    When the configured expected results file for a session does
    #                                              #    not exist, the run will be considered a failure and the expected
    #                                              #    results file will be generated using the results from the run.
    #                                              #    Developers are responsible for verifying that the results match
    #                                              #    their expectations before committing those expected results.
    #                                              #    When expected results are present, they must match for the run
    #                                              #    to be successful. When the results for a session do not match
    #                                              #    the expected results, an actual results JSON file and a CSV diff
    #                                              #    are written to the directory of the expected results file for
    #                                              #    use in evaluating the failure.
    #                                              #    Session ids are always normalized before comparing: each
    #                                              #    session's id is replaced with <NAME.session_id> (NAME is
    #                                              #    the session name or suite id). Expected results files are
    #                                              #    stored with all normalizations applied.
    #     default_normalizations: false            # optional; by default the Inferno base URL (with or without
    #                                              #    its default port) is replaced with
    #                                              #    <inferno_base_url> and ISO 8601 timestamps with
    #                                              #    <TIMESTAMP> (before normalized_strings), and 64-character
    #                                              #    lowercase hex values (e.g., SecureRandom.hex(32)) with
    #                                              #    <RANDOM_64_CHAR_HEX> (after normalized_strings).
    #                                              #    Set to false to compare them exactly.
    #     normalized_strings:                      # optional; global normalization rules applied to
    #       - "http://my-server.example.com"       # both expected and actual before comparing
    #                                              # (result messages, messages, request URLs, and
    #                                              # input/output values). Applied after the session id
    #                                              # and default normalizations, so rules can refer to
    #                                              # their placeholders (e.g. <inferno_base_url>).
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
    #   steps:                                     # Details the steps taken in the execution of the script
    #     - status: created|done|waiting           # required; other status values cannot be matched on
    #       last_completed: "1.01"                 # optional; required unless the status is created
    #                                              #           can be a full ID, short ID (e.g. "1.01"), or 'suite'
    #       session: my_name                       # optional; required when multiple sessions to indicate which session
    #                                              #           can match this step
    #                                              # each step requires exactly one of action, command,
    #                                              #   http_get, or start_run
    #       action: END_SCRIPT|NOOP|WAIT           # optional; built-in action (case-insensitive)
    #                                              #           (mutually exclusive with command/http_get/start_run)
    #       # OR
    #       command: "bundle exec ..."             # optional; arbitrary shell command (requires
    #                                              #           --allow-commands CLI flag)
    #       # OR
    #       http_get: "{wait_outputs.KEY}"         # optional; http(s) URL to send a GET request to
    #                                              #           (e.g. to resume a waiting test); does not
    #                                              #           require --allow-commands. Fails the script
    #                                              #           only if the request cannot be made.
    #                                              #           The request times out after the step's
    #                                              #           timeout (or the default poll timeout).
    #       # OR
    #       start_run:
    #         session: "my_name"                   # optional; session name or template token
    #                                              #           (e.g. {session_id}); defaults to current session
    #         runnable: "1.01"                     # required; can be a short id from the UI,
    #                                              #           an internal long id, or 'suite'
    #         inputs:                              # optional; the key must be the internal name
    #           input_name: "value"                #           for the input
    #           input_name: "@path/to/file.txt"    #           prefix value with @ to read from a file;
    #                                              #           relative paths are resolved from the
    #                                              #           directory containing this script file;
    #                                              #           template tokens in the file are substituted
    #                                              #           (JSON-escaped for .json files)
    #           input_name:                        #           YAML mappings and sequences are
    #             key: value                       #           automatically JSON-serialized, useful
    #           input_name:                        #           for auth_info and other JSON inputs
    #             - item1
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
    # Template tokens in command strings, http_get URLs, and start_run input values (including the
    # content of @path file inputs):
    #   {session_id}              — current session's Inferno session ID
    #   {NAME.session_id}         — named session's ID
    #   {result_message}          — current session's wait_result_message
    #   {NAME.result_message}     — named session's wait_result_message
    #   {wait_outputs.KEY}        — current session's wait output by name
    #   {NAME.wait_outputs.KEY}   — named session's wait output by name
    #   {inferno_base_url}        — the Inferno base URL (--inferno-base-url option, or the
    #                               configured base_url when not provided)
    # In JSON contexts (YAML mapping/sequence inputs and .json file inputs), tokens are
    # assumed to appear inside double-quoted JSON strings, and substituted values are
    # JSON-escaped accordingly.
    class ExecuteScript
      SHORT_ID_PATTERN = /\A[0-9][0-9.]*\z/
      # ISO 8601 date-times, normalized by default (see default_normalized_strings)
      TIMESTAMP_NORMALIZATION = {
        'pattern' => '/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})/',
        'replacement' => '<TIMESTAMP>'
      }.freeze
      # 64 lowercase hex characters, as generated by SecureRandom.hex(32) (a common convention for
      # wait identifiers), normalized by default (see default_fallback_normalized_strings)
      RANDOM_64_CHAR_HEX_NORMALIZATION = {
        'pattern' => '/(?<![0-9a-f])[0-9a-f]{64}(?![0-9a-f])/',
        'replacement' => '<RANDOM_64_CHAR_HEX>'
      }.freeze
      # Session names and wait output keys may not contain braces or whitespace (and names may not
      # contain '.') so that tokens are matched on their own within larger text such as JSON.
      SESSION_NAME = /[^{}.\s]+/
      WAIT_OUTPUT_KEY = /[^{}\s]+/
      SESSION_NAME_FORMAT = /\A#{SESSION_NAME}\z/
      NAMED_SESSION_ID_TOKEN = /\{(#{SESSION_NAME})\.session_id\}/
      NAMED_RESULT_MESSAGE_TOKEN = /\{(#{SESSION_NAME})\.result_message\}/
      WAIT_OUTPUT_TOKEN = /\{wait_outputs\.(#{WAIT_OUTPUT_KEY})\}/
      NAMED_WAIT_OUTPUT_TOKEN = /\{(#{SESSION_NAME})\.wait_outputs\.(#{WAIT_OUTPUT_KEY})\}/
      # Seconds subtracted from the initial last_log_time so the first
      # active-status line is logged immediately rather than after one interval.
      LOG_INTERVAL_SECONDS = 30

      ScriptSession = Struct.new(
        :key, :suite_id, :session_id, :short_id_map,
        keyword_init: true
      )

      ExecutionStatus = Struct.new(
        :done, :failed, :timed_out, :cancel_pending, :current_session, :current_timeout, :last_log_time,
        :poll_start_time, :cross_session_status, :last_step_signatures
      )

      attr_accessor :yaml_file, :options, :execution_status

      def initialize(yaml_file, options)
        self.yaml_file = yaml_file
        self.options = options
        validate_yaml_file!
        validate_step_commands!
        validate_commands_allowed!
        validate_session_names!
        self.execution_status = ExecutionStatus.new(
          done: false,
          failed: false,
          timed_out: false,
          cancel_pending: false,
          current_session: sessions.first,
          current_timeout: options[:default_poll_timeout],
          poll_start_time: nil,
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

      STEP_COMMAND_KEYS = %w[start_run action http_get command].freeze

      # Each step must specify exactly one way to continue the script.
      def validate_step_commands!
        errors = Array(script_config['steps']).each_with_index.filter_map do |step, index|
          found = STEP_COMMAND_KEYS & step.keys
          next if found.length == 1

          "Step #{index + 1} (status: #{step['status']}, last_completed: #{step['last_completed']}) " \
            "must have exactly one of #{STEP_COMMAND_KEYS.join(', ')}; " \
            "found: #{found.empty? ? 'none' : found.join(', ')}."
        end
        return if errors.empty?

        puts JSON.pretty_generate({ errors: errors.join(' ') })
        exit(1)
      end

      def validate_commands_allowed!
        return if options[:allow_commands]
        return if Array(script_config['steps']).none? { |step| step['command'].present? }

        puts JSON.pretty_generate(
          { errors: "Script contains 'command' steps but --allow-commands was not set. " \
                    'Re-run with --allow-commands to permit arbitrary shell command execution.' }
        )
        exit(1)
      end

      # Session names are used in template tokens and must be free of characters that would
      # prevent token matching. Multi-session scripts must name every session uniquely.
      def validate_session_names!
        session_configs = Array(script_config['sessions'])
        errors = missing_session_name_errors(session_configs) +
                 invalid_session_name_errors(session_configs) +
                 duplicate_session_name_errors(session_configs)
        return if errors.empty?

        puts JSON.pretty_generate({ errors: errors.join(' ') })
        exit(1)
      end

      def missing_session_name_errors(session_configs)
        return [] unless multi_session_script?

        session_configs.reject { |session_config| session_config['name'].present? }.map do |session_config|
          "Session for suite '#{session_config['suite']}' must have a name when a script has multiple sessions."
        end
      end

      def invalid_session_name_errors(session_configs)
        names = session_configs.filter_map { |session_config| session_config['name']&.to_s }
        names.grep_v(SESSION_NAME_FORMAT).map do |name|
          "Session name '#{name}' must not contain whitespace, '.', '{', or '}'."
        end
      end

      def duplicate_session_name_errors(session_configs)
        names = session_configs.filter_map { |session_config| session_config['name']&.to_s }
        names.tally.select { |_name, count| count > 1 }.keys.map do |name|
          "Duplicate session name '#{name}'. Give each session a unique name."
        end
      end

      # ---------------------------------------------------------------------------
      # Session creation
      # ---------------------------------------------------------------------------

      def create_sessions
        script_config['sessions']&.map do |session_config|
          create_session_from_config(session_config)
        end || []
      end

      def create_session_from_config(session_config)
        suite = session_config['suite']
        key = session_config['name']&.to_s || suite
        name_detail = session_config['name'] ? " with name '#{session_config['name']}'" : ''
        warn "Creating session for suite '#{suite}'#{name_detail}..."
        creator = Session::CreateSession.new(suite, session_create_options(session_config))
        session_details = creator.create_session
        script_session = ScriptSession.new(
          key: key,
          suite_id: session_details['test_suite_id'],
          session_id: session_details['id'],
          short_id_map: extract_short_ids_from_session_details(session_details)
        )
        warn "Session created: #{session_details['id']}"
        warn "  Available at #{session_display_url(script_session)}"
        script_session
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
        unless target_session
          puts JSON.pretty_generate(
            { errors: "Session '#{session_name}' not found in script sessions" }
          )
          exit(3)
        end

        test_id = target_session.short_id_map&.dig(short_id)
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
        elsif matched_step[:command] == 'HTTP_GET'
          warn "Executing: GET #{matched_step[:url]}"
          execution_status.failed = true unless execute_http_get(matched_step[:url])
          execution_status.done = execution_status.failed
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
        execution_status.poll_start_time = Time.now
        execution_status.last_log_time = Time.now - LOG_INTERVAL_SECONDS

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
            execution_status.timed_out = true
            return { command: nil, timeout: timeout, next_poll_session: nil }
          end

          sleep options[:poll_interval]
        end
      end

      # Returns a step hash to act on, or nil to keep polling.
      def handle_actionable_status(status, session, timeout)
        # A cancelled run's done status is indistinguishable from the
        # runnable completing normally, so don't match steps against it.
        return handle_cancel_completion(status, session, timeout) if execution_status.cancel_pending

        matched_step = match_step(status, session.key)

        if matched_step
          handle_matched_step(matched_step, status, session, timeout)
        elsif status['status'] == 'waiting'
          handle_unmatched_wait(status, session)
        else
          handle_unmatched_status(status, session, timeout)
        end
      end

      def handle_matched_step(matched_step, status, session, timeout)
        return nil if matched_step[:command] == 'WAIT'

        verify_step(matched_step, status, session, timeout)
      end

      def handle_unmatched_wait(status, session)
        last_completed = format_last_completed(last_completed_from_status(status), session.key)
        warn "UNHANDLED WAIT - Canceling: session=#{session.key} last_completed=#{last_completed}"
        execution_status.failed = true
        execution_status.cancel_pending = true
        attempt_cancel(session.session_id, status)
        nil
      end

      def handle_cancel_completion(status, session, timeout)
        warn "Cancellation complete: session=#{session.key} status=#{status['status']}"
        { command: nil, timeout: timeout, next_poll_session: nil }
      end

      def handle_unmatched_status(status, session, timeout)
        run_status = status['status']
        last_completed = format_last_completed(last_completed_from_status(status), session.key)
        warn "UNMATCHED: session=#{session.key} status=#{run_status} last_completed=#{last_completed}"
        execution_status.failed = true
        { command: nil, timeout: timeout, next_poll_session: nil }
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
            execution_status.cancel_pending = true
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
        elapsed = (Time.now - execution_status.poll_start_time).round
        warn "  [#{session_key}] #{status['status']} (#{test_progress(status, elapsed)})" \
             "#{poll_status_last_test}"
        execution_status.last_log_time = Time.now
      end

      def test_progress(status, elapsed)
        "completed #{status['completed_test_count']}/#{status['test_count']} tests in #{elapsed}s"
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

        log_matched_step(matched, last_completed, session_key)
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

      def log_matched_step(matched, last_completed, session_key)
        warn 'Matched step:'
        warn "  State: #{matched['state_description']}" if matched['state_description'].present?
        warn "  status=#{matched['status']} last_completed=#{format_last_completed(last_completed, session_key)}"
        warn "  Command: #{step_command_description(matched)}"
        matched_step_optional_lines(matched)
      end

      def matched_step_optional_lines(matched)
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
        elsif step.key?('http_get')
          "http_get: #{step['http_get']}"
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
        parts << start_run_inputs_description(start_run_details) if start_run_details['inputs'].present?
        parts.join(' ')
      end

      # Templated file inputs show their @path rather than the substituted content.
      def start_run_inputs_description(start_run_details)
        templated_files = start_run_details['templated_files'] || {}
        "-i #{start_run_details['inputs'].map do |k, v|
          templated_files.key?(k) ? "#{k}:#{templated_files[k]} (templated)" : "#{k}:#{v}"
        end.join(' ')}"
      end

      def resolve_command(step, status, session_key)
        if step.key?('start_run')
          start_run = apply_templates_to_start_run((step['start_run'] || {}).deep_dup, status, session_key)
          { command: 'START_RUN', start_run: }
        elsif step.key?('action')
          { command: step['action'].upcase }
        elsif step.key?('http_get')
          { command: 'HTTP_GET', url: apply_templates(step['http_get'].to_s, status, session_key) }
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
      # When +json_string+ is true, +str+ is JSON and tokens are assumed to appear inside
      # JSON string literals, so substituted values are escaped (quotes, backslashes,
      # control characters) to keep the result valid JSON.
      #
      # Session names and wait output keys in tokens cannot contain braces or whitespace,
      # so that a token inside larger text (e.g., a JSON object) is matched on its own.
      #
      # Returns the resolved string or exits 3 if a token cannot be resolved.
      def apply_templates(str, status, session_key, json_string: false)
        result = str.dup
        escape = json_string ? ->(value) { value.to_s.to_json[1..-2] } : ->(value) { value }

        # {inferno_base_url} — the Inferno base URL
        result.gsub!('{inferno_base_url}') { escape.call(inferno_base_url) }

        # {session_id} — current session
        result.gsub!('{session_id}') { escape.call(session_name_to_id_map[session_key]) }

        # {NAME.session_id} — named session
        result.gsub!(NAMED_SESSION_ID_TOKEN) do
          name = Regexp.last_match(1)
          id   = session_name_to_id_map[name]
          unless id
            puts JSON.pretty_generate({ errors: "Unknown session name '#{name}' in token {#{name}.session_id}" })
            exit(3)
          end
          escape.call(id)
        end

        # {result_message} — current session wait result message
        result.gsub!('{result_message}') do
          msg = status['wait_result_message']
          unless msg
            puts JSON.pretty_generate({ errors: 'Token {result_message} used but session is not in waiting state' })
            exit(3)
          end
          escape.call(msg)
        end

        # {NAME.result_message} — another session's wait result message
        result.gsub!(NAMED_RESULT_MESSAGE_TOKEN) do
          name       = Regexp.last_match(1)
          other_stat = cross_session_status(name)
          msg        = other_stat['wait_result_message']
          unless msg
            puts JSON.pretty_generate(
              { errors: "Token {#{name}.result_message} used but session '#{name}' is not in waiting state" }
            )
            exit(3)
          end
          escape.call(msg)
        end

        # {wait_outputs.KEY} — current session wait output
        result.gsub!(WAIT_OUTPUT_TOKEN) do
          key    = Regexp.last_match(1)
          output = find_wait_output(status['wait_outputs'], key)
          unless output
            puts JSON.pretty_generate({ errors: "Wait output '#{key}' not found in current session" })
            exit(3)
          end
          escape.call(output)
        end

        # {NAME.wait_outputs.KEY} — another session's wait output
        result.gsub!(NAMED_WAIT_OUTPUT_TOKEN) do
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
          escape.call(output)
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
          apply_templates_to_start_run_input(start_run, input_name, status, session_key)
        end

        start_run
      end

      def apply_templates_to_start_run_input(start_run, input_name, status, session_key)
        raw = start_run['inputs'][input_name]
        json_string = raw.is_a?(Array) || raw.is_a?(Hash)
        raw = raw.to_json if json_string
        value = expand_file_input_path(apply_templates(raw.to_s, status, session_key, json_string:))
        templated = apply_templates_to_file_input(value, status, session_key)
        # Remember the @path of templated files so logging can show it instead of the content
        (start_run['templated_files'] ||= {})[input_name] = value unless templated == value
        start_run['inputs'][input_name] = templated
      end

      # For an @path input, substitutes template tokens within the file's content.
      # Substituted values are JSON-escaped for .json files.
      # Returns the substituted content when any token was replaced; otherwise returns
      # the @path unchanged so that start_run reads the file as-is.
      def apply_templates_to_file_input(value, status, session_key)
        return value unless value.start_with?('@')

        path = value[1..]
        content = File.read(path, encoding: 'UTF-8')
        return value unless content.valid_encoding?

        templated = apply_templates(content, status, session_key, json_string: File.extname(path).casecmp?('.json'))
        templated == content ? value : templated
      end

      def expand_file_input_path(value)
        return value unless value.start_with?('@')

        path = value[1..]
        expanded = Pathname.new(path).absolute? ? path : File.expand_path(path, File.dirname(yaml_file))

        unless File.exist?(expanded)
          puts JSON.pretty_generate({ errors: "File input not found: #{expanded}" })
          exit(3)
        end

        "@#{expanded}"
      end

      # ---------------------------------------------------------------------------
      # Command execution
      # ---------------------------------------------------------------------------

      def execute_command(cmd)
        system(cmd)
        $CHILD_STATUS.success?
      end

      # Sends a GET request to +url+ and discards the response body. Only http(s) URLs
      # are allowed. Returns false if the URL is invalid or the request cannot be made;
      # an error (4xx or 5xx) response is logged but does not count as a failure. The request
      # times out after the current step timeout.
      def execute_http_get(url, timeout: execution_status.current_timeout)
        uri = URI.parse(url)
        unless uri.is_a?(URI::HTTP) && uri.host.present?
          warn "Invalid http_get URL (must be http or https): #{url}"
          return false
        end

        response = Faraday.new(request: { timeout: }).get(uri)
        warn "http_get received HTTP #{response.status} from #{url}" if response.status >= 400
        true
      rescue URI::InvalidURIError, Faraday::Error => e
        warn "http_get request to #{url} failed: #{e.message}"
        false
      end

      # ---------------------------------------------------------------------------
      # check results
      # ---------------------------------------------------------------------------

      def results_match_expected?(sessions)
        sessions.map do |session|
          warn "Checking results for #{session.key} session (#{session.session_id})"
          warn "  View session at #{session_display_url(session)}"

          if execution_status.timed_out
            warn '  Session timed out - skipping comparison'
            false
          elsif any_error_results?(session)
            warn '  Session contained execution errors - skipping comparison'
            false
          else
            compare_session(session)
          end
        end.all?
      end

      def inferno_base_url
        Session::Connection.inferno_base_url(options)
      end

      def session_display_url(session)
        "#{inferno_base_url}/#{session.suite_id}/#{session.session_id}"
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
        expected_file = expected_file_for_comparison(session)

        if File.exist?(expected_file)
          cmp = Session::SessionCompare.new(session.session_id, compare_options(expected_file))
          matched = cmp.results_match?
          warn "  Comparing against #{File.basename(expected_file)}"
          warn "  Actual results matched expected results? #{matched}"
          return update_expected_results(expected_file, cmp.session_results) if options[:update_expected]

          unless matched
            cmp.save_actual_results_to_file
            cmp.save_comparison_csv_to_file
          end
          matched
        else
          warn "  Expected results file not found; writing actual results to #{expected_file}"
          results = Session::SessionResults.new(session.session_id, options).results_for_session(session.session_id)
          write_expected_results(expected_file, results)
          options[:update_expected].present?
        end
      end

      # Expected results are stored normalized so that regenerating them only changes the file
      # when compared content changes.
      def write_expected_results(expected_file, results)
        File.write(expected_file, stored_expected_results(expected_file, results))
      end

      # Rewrites the expected results file whenever its stored content would change, even if
      # the results match (e.g., a file in an older format or written with other normalizations).
      def update_expected_results(expected_file, results)
        content = stored_expected_results(expected_file, results)
        if File.read(expected_file) == content
          warn '  Expected results already up to date'
        else
          File.write(expected_file, content)
          warn "  Expected results updated: wrote actual results to #{expected_file}"
        end
        true
      end

      def stored_expected_results(expected_file, results)
        normalized_strings = compare_options(expected_file)[:normalized_strings]
        JSON.pretty_generate(Session::SessionCompare.results_for_storage(results, normalized_strings))
      end

      def expected_file_for_comparison(session)
        @expected_files_for_comparison ||= {}
        @expected_files_for_comparison[session.key] ||= resolve_expected_file_for_comparison(session)
      end

      # Session ids differ between runs and can appear anywhere in results (e.g., in
      # request URLs and messages). For every session in the script, its id in this run is
      # normalized to a "<NAME.session_id>" placeholder, which is also how it is stored in
      # expected results files. All sessions are included because one session's results can
      # contain another session's id. Expected results files written before they were stored
      # normalized record the session's id in test_session_id; that id is normalized too so
      # those files still compare until they are regenerated.
      def session_id_normalized_strings
        @session_id_normalized_strings ||= sessions.flat_map do |session|
          replacement = "<#{session.key}.session_id>"
          [session.session_id, expected_session_id(session)].compact.uniq.map do |id|
            { 'pattern' => id, 'replacement' => replacement }
          end
        end
      end

      def expected_session_id(session)
        expected_file = expected_file_for_comparison(session)
        return unless File.exist?(expected_file)

        Array(JSON.parse(File.read(expected_file))).filter_map { |result| result['test_session_id'] }.first
      rescue JSON::ParserError
        nil
      end

      def resolve_expected_file_for_comparison(session)
        default_file = resolve_expected_file(session.key)
        alternates = Array(comparison_session_config(session.key)['alternate_expected_files'])
        return default_file if alternates.empty?

        session_details = Session::SessionDetails.new(session.session_id, options).details_for_session
        session_inputs = Session::SessionData.new(session.session_id, options).session_data

        alternates.each do |alt|
          conditions = Array(alt['when'])
          next if conditions.empty?
          unless conditions.all? { |cond| session_detail_condition_matches?(cond, session_details, session_inputs) }
            next
          end

          file = File.expand_path(alt['file'], yaml_directory)
          return file
        end

        default_file
      end

      def session_detail_condition_matches?(condition, session_details, session_inputs)
        return false unless condition_has_field_and_pattern?(condition)

        field = condition['field']
        matches_pattern = condition['matches']
        not_matches_pattern = condition['not_matches']

        if field == 'configuration_messages'
          configuration_messages_match?(session_details['test_suite'] || {}, matches_pattern, not_matches_pattern)
        elsif field == 'inferno_base_url'
          string_matches?(inferno_base_url, matches_pattern, not_matches_pattern)
        elsif field.start_with?('inputs.')
          input_name = field.delete_prefix('inputs.')
          test_suite_input_matches?(session_inputs || [], input_name, matches_pattern, not_matches_pattern)
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

      def test_suite_input_matches?(suite_data, input_name, matches_pattern, not_matches_pattern)
        value = suite_data.find { |input| input['name'] == input_name }&.dig('value')
        string_matches?(value.to_s, matches_pattern, not_matches_pattern)
      end

      def comparison_config
        @comparison_config ||= script_config['comparison_config'] || {}
      end

      def compare_options(expected_file)
        normalized_strings = session_id_normalized_strings + default_normalized_strings +
                             Array(comparison_config['normalized_strings']) + default_fallback_normalized_strings
        {
          expected_results_file: expected_file,
          compare_messages: options[:compare_messages],
          compare_result_message: options[:compare_result_message],
          compare_requests: options[:compare_requests],
          compare_io: options[:compare_io],
          only_different_messages: options[:only_different_messages],
          inferno_base_url: options[:inferno_base_url],
          normalized_strings:
        }
      end

      def default_normalizations?
        comparison_config['default_normalizations'].to_s.downcase != 'false'
      end

      # Values that vary by run or by the Inferno being run against, normalized before the
      # script's normalized_strings so that its rules can refer to their placeholders.
      def default_normalized_strings
        return [] unless default_normalizations?

        base_url_rule = { 'patterns' => inferno_base_url_forms, 'replacement' => '<inferno_base_url>' }
        [(base_url_rule if inferno_base_url.present?), TIMESTAMP_NORMALIZATION].compact
      end

      # The base URL both with and without its scheme's default port (e.g., :443 for https), since
      # recorded request URLs may spell out the default port.
      def inferno_base_url_forms
        uri = URI.parse(inferno_base_url)
        return [inferno_base_url] unless uri.host.present? && uri.port == uri.default_port

        without_port = "#{uri.scheme}://#{uri.host}#{uri.path}"
        [without_port, "#{uri.scheme}://#{uri.host}:#{uri.port}#{uri.path}"]
      rescue URI::InvalidURIError
        [inferno_base_url]
      end

      # Catch-all normalizations applied after the script's normalized_strings, so that more
      # specific rules matching the same values take precedence.
      def default_fallback_normalized_strings
        default_normalizations? ? [RANDOM_64_CHAR_HEX_NORMALIZATION] : []
      end
    end
  end
end
