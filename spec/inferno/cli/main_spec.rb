require 'rspec'
require 'thor'
require 'inferno/apps/cli/main'
require 'inferno/version'

RSpec.describe Inferno::CLI::Main do
  describe '#execute_script' do
    before do
      allow(Inferno::Utils::ExecutionScriptRunner).to receive(:run_all)
      allow(Inferno::CLI::ExecuteScript).to receive(:new)
        .and_return(instance_double(Inferno::CLI::ExecuteScript, run: nil))
    end

    it 'runs all scripts when no pattern is given' do
      described_class.start(['execute_script'])
      expect(Inferno::Utils::ExecutionScriptRunner)
        .to have_received(:run_all).with(hash_including(pattern: 'execution_scripts/**/*.yaml'))
      expect(Inferno::CLI::ExecuteScript).to_not have_received(:new)
    end

    it 'runs all scripts when the pattern has wildcards, even if only one script matches' do
      allow(Dir).to receive(:glob).and_return(['execution_scripts/demo/only_one.yaml'])
      described_class.start(['execute_script', 'execution_scripts/demo/only_*.yaml'])
      expect(Inferno::Utils::ExecutionScriptRunner)
        .to have_received(:run_all).with(hash_including(pattern: 'execution_scripts/demo/only_*.yaml'))
      expect(Inferno::CLI::ExecuteScript).to_not have_received(:new)
    end

    it 'runs a single script directly when given a path without wildcards' do
      described_class.start(['execute_script', 'execution_scripts/demo/demo_wait_group.yaml'])
      expect(Inferno::CLI::ExecuteScript)
        .to have_received(:new).with('execution_scripts/demo/demo_wait_group.yaml', anything)
      expect(Inferno::Utils::ExecutionScriptRunner).to_not have_received(:run_all)
    end

    %w[execute_scripts execution_scripts].each do |alias_name|
      # An unknown command makes Thor exit, so a missing alias is caught as an unexpected SystemExit
      it "is also available as #{alias_name}" do
        expect { described_class.start([alias_name, 'execution_scripts/demo/demo_wait_group.yaml']) }
          .to_not raise_error
        expect(Inferno::CLI::ExecuteScript)
          .to have_received(:new).with('execution_scripts/demo/demo_wait_group.yaml', anything)

        expect { described_class.start([alias_name]) }.to_not raise_error
        expect(Inferno::Utils::ExecutionScriptRunner)
          .to have_received(:run_all).with(hash_including(pattern: 'execution_scripts/**/*.yaml'))
      end
    end
  end

  context 'with version command' do
    it 'outputs current Inferno version' do
      expect { described_class.new.version }.to output("Inferno Core v#{Inferno::VERSION}\n").to_stdout
    end
  end
end
