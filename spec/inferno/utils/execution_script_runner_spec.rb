require_relative '../../../lib/inferno/utils/execution_script_runner'

RSpec.describe Inferno::Utils::ExecutionScriptRunner do
  describe '.run_all' do
    let(:passing_status) { instance_double(Process::Status, exitstatus: 0) }
    let(:default_scripts) { ['execution_scripts/my_test.yaml'] }

    before do
      allow(Dir).to receive(:glob).and_return(default_scripts)
      allow(Open3).to receive(:capture2e).and_return(['', passing_status])
      allow(described_class).to receive(:puts)
      allow(described_class).to receive(:warn)
    end

    context 'when no scripts are found' do
      before { allow(Dir).to receive(:glob).and_return([]) }

      it 'exits with code 1' do
        expect { described_class.run_all }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
      end
    end

    context 'when all scripts pass' do
      it 'does not exit' do
        expect { described_class.run_all }.to_not raise_error
      end

      it 'invokes the execute_script CLI command for each script' do
        allow(Open3).to receive(:capture2e).with(
          'bundle', 'exec', 'inferno', 'execute_script', 'execution_scripts/my_test.yaml'
        ).and_return(['', passing_status])

        described_class.run_all

        expect(Open3).to have_received(:capture2e).with(
          'bundle', 'exec', 'inferno', 'execute_script', 'execution_scripts/my_test.yaml'
        )
      end
    end

    context 'when a script fails' do
      let(:failing_status) { instance_double(Process::Status, exitstatus: 1) }

      before { allow(Open3).to receive(:capture2e).and_return(['', failing_status]) }

      it 'exits with code 1' do
        expect { described_class.run_all }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
      end
    end

    context 'when inferno_base_url is provided' do
      it 'passes --inferno-base-url to the command' do
        allow(Open3).to receive(:capture2e).with(
          'bundle', 'exec', 'inferno', 'execute_script', 'execution_scripts/my_test.yaml',
          '--inferno-base-url', 'http://localhost:4567'
        ).and_return(['', passing_status])

        described_class.run_all(inferno_base_url: 'http://localhost:4567')

        expect(Open3).to have_received(:capture2e).with(
          'bundle', 'exec', 'inferno', 'execute_script', 'execution_scripts/my_test.yaml',
          '--inferno-base-url', 'http://localhost:4567'
        )
      end
    end

    context 'when the script filename includes _with_commands' do
      before do
        allow(Dir).to receive(:glob).and_return(['execution_scripts/my_test_with_commands.yaml'])
      end

      it 'passes --allow-commands to the command' do
        allow(Open3).to receive(:capture2e).with(
          'bundle', 'exec', 'inferno', 'execute_script', 'execution_scripts/my_test_with_commands.yaml',
          '--allow-commands'
        ).and_return(['', passing_status])

        described_class.run_all

        expect(Open3).to have_received(:capture2e).with(
          'bundle', 'exec', 'inferno', 'execute_script', 'execution_scripts/my_test_with_commands.yaml',
          '--allow-commands'
        )
      end
    end

    context 'when a non-YAML file is in the glob results' do
      before do
        allow(Dir).to receive(:glob)
          .and_return(['execution_scripts/my_test.yaml', 'execution_scripts/notes.txt'])
      end

      it 'skips the non-YAML file' do
        described_class.run_all

        expect(Open3).to have_received(:capture2e).once
      end
    end

    context 'with allow_known_failures: false (default)' do
      let(:exit_3_status) { instance_double(Process::Status, exitstatus: 3) }

      before do
        allow(Dir).to receive(:glob).and_return(['execution_scripts/my_test_failure.yaml'])
        allow(Open3).to receive(:capture2e).and_return(['', exit_3_status])
      end

      it 'treats exit code 3 on a _failure script as failure' do
        expect { described_class.run_all }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
      end
    end

    context 'with allow_known_failures: true' do
      let(:exit_3_status) { instance_double(Process::Status, exitstatus: 3) }

      before { allow(Dir).to receive(:glob).and_return(['execution_scripts/my_test_failure.yaml']) }

      context 'when a _failure script exits with an error before comparison and no expected file exists' do
        before do
          allow(Open3).to receive(:capture2e)
            .and_return(["{\"errors\": \"something went wrong\"}\n", exit_3_status])
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?)
            .with('execution_scripts/my_test_failure_expected.json')
            .and_return(false)
        end

        it 'treats it as a pass' do
          expect { described_class.run_all(allow_known_failures: true) }.to_not raise_error
        end
      end

      context 'when a _failure script exits with an error before comparison but an expected file exists' do
        before do
          allow(Open3).to receive(:capture2e)
            .and_return(["{\"errors\": \"something went wrong\"}\n", exit_3_status])
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?)
            .with('execution_scripts/my_test_failure_expected.json')
            .and_return(true)
        end

        it 'treats it as a failure' do
          expect { described_class.run_all(allow_known_failures: true) }
            .to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
        end
      end

      context 'when a _failure script exits 3 and results matched expected' do
        before do
          allow(Open3).to receive(:capture2e)
            .and_return(["Actual results matched expected results? true\n", exit_3_status])
        end

        it 'treats it as a pass' do
          expect { described_class.run_all(allow_known_failures: true) }.to_not raise_error
        end
      end

      context 'when a _failure script exits 3 but results did not match expected' do
        before do
          allow(Open3).to receive(:capture2e)
            .and_return(["Actual results matched expected results? false\n", exit_3_status])
        end

        it 'treats it as a failure' do
          expect { described_class.run_all(allow_known_failures: true) }
            .to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
        end
      end

      context 'when a non-_failure script exits 3' do
        before do
          allow(Dir).to receive(:glob).and_return(['execution_scripts/my_test.yaml'])
          allow(Open3).to receive(:capture2e).and_return(['', exit_3_status])
        end

        it 'treats it as a failure' do
          expect { described_class.run_all(allow_known_failures: true) }
            .to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
        end
      end
    end
  end
end
