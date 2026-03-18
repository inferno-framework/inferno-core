begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
rescue LoadError # rubocop:disable Lint/SuppressedException
end

namespace :db do
  desc 'Apply changes to the database'
  task :migrate do
    require_relative 'lib/inferno/config/application'
    require_relative 'lib/inferno/apps/cli/migration'

    Inferno::CLI::Migration.new.run
  end
end

namespace :execute_scripts do
  desc 'Run all execution script YAML files against a local Inferno instance (already running). ' \
       'Optional FILTER env var restricts by File.fnmatch pattern, e.g. FILTER="execution_scripts/demo/*"'
  task :run_all do
    require 'open3'

    pattern = ENV.fetch('FILTER', 'execution_scripts/**/*.yaml')
    scripts = Dir.glob(pattern)

    if scripts.empty?
      warn "No scripts found matching: #{pattern}"
      exit 1
    end

    puts "Found #{scripts.length} script(s) to run.\n\n"

    passed = []
    failed = []

    scripts.each do |config|
      puts '=' * 60
      puts "Running: #{config}"
      puts '=' * 60

      output, status = Open3.capture2e('bundle', 'exec', 'inferno', 'execute_script', config)
      print output
      rc = status.exitstatus

      known_failure = File.basename(config, '.yaml').end_with?('_failure')

      result =
        if known_failure && rc == 3
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
