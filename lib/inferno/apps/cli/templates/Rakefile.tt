begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
rescue LoadError # rubocop:disable Lint/SuppressedException
end

namespace :execute_scripts do
  desc 'Run all execution script YAML files against a local Inferno instance (already running). ' \
       'Optional FILTER env var restricts by File.fnmatch pattern, e.g. FILTER="execution_scripts/demo/*". ' \
       'Optional INFERNO_BASE_URL env var sets the target Inferno URL, e.g. INFERNO_BASE_URL="http://localhost:4567/"'
  task :run_all do
    require 'open3'

    pattern = ENV.fetch('FILTER', 'execution_scripts/**/*.yaml')
    inferno_base_url = ENV.fetch('INFERNO_BASE_URL', nil)
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
      print output
      rc = status.exitstatus

      if rc.zero?
        puts '=> PASS'
        passed << config
      else
        puts "=> FAIL (exit code #{rc})"
        failed << config
      end

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

namespace :db do
  desc 'Apply changes to the database'
  task :migrate do
    require 'inferno/config/application'
    require 'inferno/utils/migration'
    Inferno::Utils::Migration.new.run
  end
end
