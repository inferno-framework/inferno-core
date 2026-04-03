require 'open3'

module Inferno
  module Utils
    module ExecutionScriptRunner
      def self.run_all(pattern: 'execution_scripts/**/*.yaml', inferno_base_url: nil, allow_known_failures: false)
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

          result = run_script(config, inferno_base_url:, allow_known_failures:)
          (result == :pass ? passed : failed) << config

          puts
        end

        print_summary(passed, failed)
      end

      def self.run_script(config, inferno_base_url:, allow_known_failures:)
        puts '=' * 60
        puts "Running: #{config}"
        puts '=' * 60

        allow_commands = File.basename(config, '.yaml').include?('_with_commands')
        cmd = ['bundle', 'exec', 'inferno', 'execute_script', config]
        cmd += ['--inferno-base-url', inferno_base_url] if inferno_base_url
        cmd += ['--allow-commands'] if allow_commands
        output, status = Open3.capture2e(*cmd)
        puts output

        determine_result(config, status.exitstatus, output, allow_known_failures)
      end

      def self.determine_result(config, return_code, output, allow_known_failures)
        if allow_known_failures && File.basename(config, '.yaml').end_with?('_failure') && return_code == 3
          if output.include?('Actual results matched expected results? true')
            puts '=> PASS (known-failure script exited with 3 and results matched expected)'
            :pass
          else
            puts '=> FAIL (exited with 3 but results did not match expected)'
            :fail
          end
        elsif return_code.zero?
          puts '=> PASS'
          :pass
        else
          puts "=> FAIL (exit code #{return_code})"
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
