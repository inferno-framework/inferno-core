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

          puts '=' * 60
          puts "Running: #{config}"
          puts '=' * 60

          allow_commands = File.basename(config, '.yaml').include?('_with_commands')
          cmd = ['bundle', 'exec', 'inferno', 'execute_script', config]
          cmd += ['--inferno-base-url', inferno_base_url] if inferno_base_url
          cmd += ['--allow-commands'] if allow_commands
          output, status = Open3.capture2e(*cmd)
          puts output
          rc = status.exitstatus

          result =
            if allow_known_failures && File.basename(config, '.yaml').end_with?('_failure') && rc == 3
              if output.include?('Actual results matched expected results? true')
                puts '=> PASS (known-failure script exited with 3 and results matched expected)'
                :pass
              else
                puts '=> FAIL (exited with 3 but results did not match expected)'
                :fail
              end
            elsif rc.zero?
              puts '=> PASS'
              :pass
            else
              puts "=> FAIL (exit code #{rc})"
              :fail
            end

          (result == :pass ? passed : failed) << config

          puts
        end

        puts '=' * 60
        puts "Results: #{passed.length} passed, #{failed.length} failed"
        puts '=' * 60

        if passed.any?
          puts 'Passed:'
          passed.each { |s| puts "  #{s}" }
        end

        if failed.any?
          puts 'Failed:'
          failed.each { |s| puts "  #{s}" }
          exit 1
        end
      end
    end
  end
end
