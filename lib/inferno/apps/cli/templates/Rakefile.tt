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
    require 'inferno/utils/execution_script_runner'
    Inferno::Utils::ExecutionScriptRunner.run_all(
      pattern: ENV.fetch('FILTER', 'execution_scripts/**/*.yaml'),
      inferno_base_url: ENV.fetch('INFERNO_BASE_URL', nil)
    )
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
