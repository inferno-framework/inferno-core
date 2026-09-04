require 'open3'

module Inferno
  module Utils
    module ExecutionScriptRunner
      def self.run_all(pattern: 'execution_scripts/**/*.yaml', inferno_base_url: nil,
                       allow_known_errors: false, allow_commands: false,
                       compare_messages: true, compare_result_message: true,
                       poll_interval: 3, default_poll_timeout: 120,
                       only_different_messages: true)
        scripts = Dir.glob(pattern)

        if scripts.empty?
          warn "No scripts found matching: #{pattern}"
          exit 1
        end

        puts "Found #{scripts.length} script(s) to run.\n\n"

        passed = []
        failed = []

        scripts.each do |config|
          unless config.end_with?('.yaml', '.yml')
            warn "Skipping non-YAML file: #{config}"
            next
          end

          result = run_script(config, inferno_base_url:, allow_known_errors:, allow_commands:,
                                      compare_messages:, compare_result_message:,
                                      poll_interval:, default_poll_timeout:,
                                      only_different_messages:)
          (result == :pass ? passed : failed) << config

          puts
        end

        print_summary(passed, failed)
      end

      def self.run_script(config, inferno_base_url:, allow_known_errors:, allow_commands: false,
                          compare_messages: true, compare_result_message: true,
                          poll_interval: 3, default_poll_timeout: 120,
                          only_different_messages: true)
        puts '=' * 60
        puts "Running: #{config}"
        puts '=' * 60

        allow_commands ||= File.basename(config, '.yaml').include?('_with_commands')
        cmd = build_command(config, inferno_base_url:, allow_commands:, compare_messages:,
                                    compare_result_message:, poll_interval:, default_poll_timeout:,
                                    only_different_messages:)
        output, exitstatus = stream_command(*cmd)

        determine_result(config, exitstatus, output, allow_known_errors)
      end

      # @private
      def self.build_command(config, inferno_base_url:, allow_commands:, compare_messages:,
                             compare_result_message:, poll_interval:, default_poll_timeout:,
                             only_different_messages:)
        cmd = ['bundle', 'exec', 'inferno', 'execute_script', config]
        cmd += ['--inferno-base-url', inferno_base_url] if inferno_base_url
        cmd += ['--allow-commands'] if allow_commands
        cmd += ['--poll-interval', poll_interval.to_s] if poll_interval != 3
        cmd += ['--default-poll-timeout', default_poll_timeout.to_s] if default_poll_timeout != 120
        cmd + comparison_flags(compare_messages:, compare_result_message:, only_different_messages:)
      end

      # @private
      def self.comparison_flags(compare_messages:, compare_result_message:, only_different_messages:)
        flags = []
        flags << '--no-compare-messages' unless compare_messages
        flags << '--no-compare-result-message' unless compare_result_message
        flags << '--no-only-different-messages' unless only_different_messages
        flags
      end

      # Runs +cmd+ as a subprocess, echoing its combined stdout/stderr to the console
      # line-by-line as it's produced (rather than buffering until the process exits),
      # while still returning the full captured output for result determination.
      def self.stream_command(*cmd)
        output = +''
        exitstatus = nil

        Open3.popen2e(*cmd) do |stdin, stdout_and_stderr, wait_thread|
          stdin.close
          stdout_and_stderr.each_line do |line|
            puts line
            output << line
          end
          exitstatus = wait_thread.value.exitstatus
        end

        [output, exitstatus]
      end

      def self.determine_result(config, return_code, output, allow_known_errors)
        known_error = allow_known_errors && File.basename(config, '.yaml').end_with?('_error')
        return determine_known_error_result(config, output) if known_error && !return_code.zero?
        return (:pass.tap { puts '=> PASS' }) if return_code.zero?

        puts "=> FAIL (exit code #{return_code})"
        :fail
      end

      def self.determine_known_error_result(config, output)
        expected_file = File.join(File.dirname(config), "#{File.basename(config, '.yaml')}_expected.json")
        if (output.include?('"errors"') || output.include?('skipping comparison')) && !File.exist?(expected_file)
          puts '=> PASS (known-error script exited with 3 due to expected error before comparison)'
          :pass
        elsif output.include?('Actual results matched expected results? true')
          puts '=> PASS (known-error script exited with 3 and results matched expected)'
          :pass
        else
          puts '=> FAIL (exited with 3 but results did not match expected)'
          :fail
        end
      end

      def self.print_summary(passed, failed)
        puts '=' * 60
        puts "Results: #{passed.length} passed, #{failed.length} failed"
        puts '=' * 60

        if passed.any?
          puts 'Passed:'
          passed.each { |s| puts "  #{s}" }
        end

        return unless failed.any?

        puts 'Failed:'
        failed.each { |s| puts "  #{s}" }
        exit 1
      end
    end
  end
end
