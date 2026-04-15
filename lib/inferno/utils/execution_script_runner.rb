require 'open3'

module Inferno
  module Utils
    module ExecutionScriptRunner
      def self.run_all(pattern: 'execution_scripts/**/*.yaml', inferno_base_url: nil, allow_known_errors: false)
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

          result = run_script(config, inferno_base_url:, allow_known_errors:)
          (result == :pass ? passed : failed) << config

          puts
        end

        print_summary(passed, failed)
      end

      def self.run_script(config, inferno_base_url:, allow_known_errors:)
        puts '=' * 60
        puts "Running: #{config}"
        puts '=' * 60

        allow_commands = File.basename(config, '.yaml').include?('_with_commands')
        cmd = ['bundle', 'exec', 'inferno', 'execute_script', config]
        cmd += ['--inferno-base-url', inferno_base_url] if inferno_base_url
        cmd += ['--allow-commands'] if allow_commands
        output, status = Open3.capture2e(*cmd)
        puts output

        determine_result(config, status.exitstatus, output, allow_known_errors)
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
        if output.include?('"errors"') && !File.exist?(expected_file)
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
