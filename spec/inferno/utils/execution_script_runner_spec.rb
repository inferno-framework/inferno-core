require_relative '../../../lib/inferno/utils/execution_script_runner'

RSpec.describe Inferno::Utils::ExecutionScriptRunner do
  describe '.run_all' do
    let(:default_scripts) { ['execution_scripts/my_test.yaml'] }

    # Stubs Open3.popen2e to yield fake stdin/output/wait_thread objects, mirroring
    # how the real method yields to the block passed by stream_command.
    def stub_subprocess(*cmd_args, output: '', exitstatus: 0)
      stdin = instance_double(IO, close: nil)
      wait_thread = instance_double(Thread, value: instance_double(Process::Status, exitstatus:))
      stub = allow(Open3).to receive(:popen2e)
      stub = stub.with(*cmd_args) if cmd_args.any?
      stub.and_yield(stdin, StringIO.new(output), wait_thread)
    end

    before do
      allow(Dir).to receive(:glob).and_return(default_scripts)
      stub_subprocess(output: '', exitstatus: 0)
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
        stub_subprocess('bundle', 'exec', 'inferno', 'execute_script', 'execution_scripts/my_test.yaml',
                        output: '', exitstatus: 0)

        described_class.run_all

        expect(Open3).to have_received(:popen2e).with(
          'bundle', 'exec', 'inferno', 'execute_script', 'execution_scripts/my_test.yaml'
        )
      end
    end

    context 'when the subprocess produces output' do
      it 'streams each line to the console as it is produced, rather than buffering it' do
        stub_subprocess(output: "line one\nline two\n", exitstatus: 0)

        described_class.run_all

        expect(described_class).to have_received(:puts).with("line one\n").ordered
        expect(described_class).to have_received(:puts).with("line two\n").ordered
      end
    end

    context 'when a script fails' do
      before { stub_subprocess(output: '', exitstatus: 1) }

      it 'exits with code 1' do
        expect { described_class.run_all }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
      end
    end

    context 'when inferno_base_url is provided' do
      it 'passes --inferno-base-url to the command' do
        stub_subprocess(
          'bundle', 'exec', 'inferno', 'execute_script', 'execution_scripts/my_test.yaml',
          '--inferno-base-url', 'http://localhost:4567',
          output: '', exitstatus: 0
        )

        described_class.run_all(inferno_base_url: 'http://localhost:4567')

        expect(Open3).to have_received(:popen2e).with(
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
        stub_subprocess(
          'bundle', 'exec', 'inferno', 'execute_script', 'execution_scripts/my_test_with_commands.yaml',
          '--allow-commands',
          output: '', exitstatus: 0
        )

        described_class.run_all

        expect(Open3).to have_received(:popen2e).with(
          'bundle', 'exec', 'inferno', 'execute_script', 'execution_scripts/my_test_with_commands.yaml',
          '--allow-commands'
        )
      end
    end

    context 'when allow_commands is explicitly passed' do
      it 'passes --allow-commands even when the filename lacks the _with_commands convention' do
        stub_subprocess(
          'bundle', 'exec', 'inferno', 'execute_script', 'execution_scripts/my_test.yaml',
          '--allow-commands',
          output: '', exitstatus: 0
        )

        described_class.run_all(allow_commands: true)

        expect(Open3).to have_received(:popen2e).with(
          'bundle', 'exec', 'inferno', 'execute_script', 'execution_scripts/my_test.yaml',
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

        expect(Open3).to have_received(:popen2e).once
      end
    end

    context 'with allow_known_errors: false (default)' do
      before do
        allow(Dir).to receive(:glob).and_return(['execution_scripts/my_test_error.yaml'])
        stub_subprocess(output: '', exitstatus: 3)
      end

      it 'treats exit code 3 on a _error script as failure' do
        expect { described_class.run_all }.to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
      end
    end

    context 'with allow_known_errors: true' do
      before { allow(Dir).to receive(:glob).and_return(['execution_scripts/my_test_error.yaml']) }

      context 'when a _error script exits with an error before comparison and no expected file exists' do
        before do
          stub_subprocess(output: "{\"errors\": \"something went wrong\"}\n", exitstatus: 3)
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?)
            .with('execution_scripts/my_test_error_expected.json')
            .and_return(false)
        end

        it 'treats it as a pass' do
          expect { described_class.run_all(allow_known_errors: true) }.to_not raise_error
        end
      end

      context 'when a _error script exits with an error before comparison but an expected file exists' do
        before do
          stub_subprocess(output: "{\"errors\": \"something went wrong\"}\n", exitstatus: 3)
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?)
            .with('execution_scripts/my_test_error_expected.json')
            .and_return(true)
        end

        it 'treats it as a failure' do
          expect { described_class.run_all(allow_known_errors: true) }
            .to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
        end
      end

      context 'when a _error script exits 3 and results matched expected' do
        before do
          stub_subprocess(output: "Actual results matched expected results? true\n", exitstatus: 3)
        end

        it 'treats it as a pass' do
          expect { described_class.run_all(allow_known_errors: true) }.to_not raise_error
        end
      end

      context 'when a _error script exits 3 but results did not match expected' do
        before do
          stub_subprocess(output: "Actual results matched expected results? false\n", exitstatus: 3)
        end

        it 'treats it as a failure' do
          expect { described_class.run_all(allow_known_errors: true) }
            .to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
        end
      end

      context 'when a non-_error script exits 3' do
        before do
          allow(Dir).to receive(:glob).and_return(['execution_scripts/my_test.yaml'])
          stub_subprocess(output: '', exitstatus: 3)
        end

        it 'treats it as a failure' do
          expect { described_class.run_all(allow_known_errors: true) }
            .to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }
        end
      end
    end
  end
end
