require_relative '../../../../lib/inferno/apps/cli/execute'

RSpec.describe Inferno::CLI::Execute do # rubocop:disable RSpec/FilePath
  let(:instance) { described_class.new }

  describe '.suppress_output' do
    it 'disables stdout' do
      expect do
        described_class.suppress_output { puts 'Hide me' }
      end.to_not output(/.+/).to_stdout_from_any_process
    end
  end

  describe '.boot_full_inferno' do
    it 'does not raise error' do
      expect { described_class.boot_full_inferno }.to_not raise_error(StandardError)
    end
  end

  describe '#print_help_and_exit' do
    it 'outputs something and exits' do
      expect do
        expect { instance.print_help_and_exit }.to output(/.+/).to_stdout
      end.to raise_error(SystemExit)
    end
  end

  describe '#outputter' do
    it 'returns an object that responds to print_start_message' do
      expect(instance.outputter).to respond_to(:print_start_message)
    end

    it 'returns an object that responds to print_around_run' do
      expect(instance.outputter).to respond_to(:print_around_run)
    end

    it 'returns an object whose print_around_run yields' do
      expect do
        expect { |b| instance.outputter.print_around_run({}, &b) }.to yield_control
      end.to output(/.?/).to_stdout # required to prevent output in rspec
    end

    it 'returns an object that responds to print_results' do
      expect(instance.outputter).to respond_to(:print_results)
    end

    it 'returns an object that responds to print_end_message' do
      expect(instance.outputter).to respond_to(:print_end_message)
    end

    it 'returns an object that responds to print_error' do
      expect(instance.outputter).to respond_to(:print_error)
    end

    it 'returns an object whose print_error does not raise exception nor exit' do
      allow(instance).to receive(:options).and_return({})
      expect do
        expect { instance.outputter.print_error({}, StandardError.new('my error')) }.to_not raise_error
      end.to output(/.?/).to_stdout # required to prevent output in rspec
    end
  end

  describe '#selected_runnables' do
    it 'returns empty array when no short ids given' do
      allow(instance).to receive(:options).and_return({ suite: 'basic' })
      expect(instance.selected_runnables).to eq([])
    end

    it 'returns runnables when group short ids are given' do
      allow(instance).to receive(:options).and_return({ suite: 'basic', groups: ['1'] })
      expect(instance.selected_runnables.length).to eq(1)
    end

    it 'returns runnables when test short ids are given' do
      allow(instance).to receive(:options).and_return({ suite: 'basic', tests: ['1.01'] })
      expect(instance.selected_runnables.length).to eq(1)
    end

    it 'returns either runnable when short ids are given' do
      allow(instance).to receive(:options).and_return({ suite: 'basic', short_ids: ['1.01'] })
      expect(instance.selected_runnables.length).to eq(1)
    end

    it 'raises error when redundant short ids are given' do
      allow(instance).to receive(:options).and_return({ suite: 'basic', groups: ['1'], tests: ['1.01'] })
      expect{ instance.selected_runnables }.to raise_error
    end

    it 'raises error when a group is given test short ids' do
      allow(instance).to receive(:options).and_return({ suite: 'basic', groups: ['1.01'] })
      expect{ instance.selected_runnables }.to raise_error
    end
  end

  describe '#suite' do
    it 'returns the correct Inferno TestSuite entity' do
      allow(instance).to receive(:options).and_return({ suite: 'basic' })
      expect(instance.suite).to eq(BasicTestSuite::Suite)
    end

    it 'raises standard error if no suite provided' do
      expect { instance.suite }.to raise_error(StandardError)
    end
  end

  describe '#test_run' do
    { suite: BasicTestSuite::Suite, group: BasicTestSuite::AbcGroup,
      test: BasicTestSuite::AbcGroup.tests.first }.each do |type, runnable|
      it "returns a test run for #{type}" do
        allow(instance).to receive(:options).and_return({ suite: 'basic' })
        expect(instance.test_run(runnable)).to be_instance_of Inferno::Entities::TestRun
      end
    end
  end

  describe '#test_session' do
    it 'returns test session given suite options' do
      allow(instance).to receive(:options).and_return({ suite: 'basic', suite_options: { option: 'a' } })
      allow(instance).to receive(:suite).and_return(BasicTestSuite::Suite)
      expect(instance.test_session).to be_instance_of Inferno::Entities::TestSession
    end
  end

  describe '#create_params' do
    let(:test_suite) { BasicTestSuite::Suite }
    let(:test_session) { create(:test_session) }
    let(:inputs_hash) { { url: 'https://example.com' } }
    let(:inputs_array) { [{ name: :url, value: 'https://example.com' }] }

    it 'returns test run params' do
      allow(instance).to receive(:options).and_return({ suite: test_suite.id, inputs: inputs_hash })
      allow(instance).to receive(:runnable_type).and_return(:suite)

      result = instance.create_params(test_session, test_suite)
      expect(result).to eq({ test_session_id: test_session.id, test_suite_id: test_suite.id, inputs: inputs_array })
    end
  end

  describe '#dispatch_job' do
    let(:test_session) { test_run.test_session }
    let(:test_run) { repo_create(:test_run, test_suite_id: 'basic') }

    it 'supresses output if verbose is false' do
      allow(instance).to receive(:test_session).and_return(test_session)
      allow(instance).to receive(:options).and_return({ suite: 'basic', verbose: false })

      expect { instance.dispatch_job(test_run) }.to_not output(/.+/).to_stdout_from_any_process
    end
  end

  describe '#validate_unique_runnables' do
    let(:runnable) { BasicTestSuite::AbcGroup }
    let(:another_runnable) { BasicTestSuite::DefGroup }

    it 'returns runnables if they are unique' do
      expect( instance.validate_unique_runnables([runnable, another_runnable]) ).to eq([runnable, another_runnable])
    end
  
    it 'raises an error for duplicate runnables' do
      expect { instance.validate_unique_runnables([runnable, runnable]) }.to raise_error(StandardError)
    end
  
    it 'raises an error if a runnable is included in another' do
      child = runnable.tests.first
      expect { instance.validate_unique_runnables([runnable, child]) }.to raise_error(StandardError)
    end
  end

  describe '#runnable_is_included_in?' do
    let(:parent) { BasicTestSuite::Suite }
    let(:group) { parent.groups.first }
    let(:test) { group.tests.first }

    it 'returns false when runnable has no parents' do
      expect( instance.runnable_is_included_in?(parent, parent) ).to be_falsey;
    end

    it 'returns true when runnable is a child of parent' do
      expect( instance.runnable_is_included_in?(group, parent) ).to be_truthy;
    end

    it 'returns true when runnable is a nested child of parent' do
      expect( instance.runnable_is_included_in?(test, parent) ).to be_truthy;
    end
  end

  describe '#groups' do
    it 'parses group by short id' do
      allow(instance).to receive(:options).and_return({ suite: 'basic', groups: ['1'] })
      expect(instance.groups).to eq([BasicTestSuite::Suite.groups.first])
    end
  end

  describe '#tests' do
    it 'parses test by short id' do
      allow(instance).to receive(:options).and_return({ suite: 'basic', tests: ['1.01'] })
      expect(instance.tests).to eq([BasicTestSuite::Suite.groups.first.tests.first])
    end
  end

  describe '#find_by_short_id' do
    it 'raises standard error when entity not found by short id' do
      expect do
        instance.find_by_short_id(Inferno::Repositories::Tests.new, 'does_not_exist')
      end.to raise_error(StandardError)
    end
  end

  describe '#thor_hash_to_suite_options_array' do
    let(:hash) { { us_core: 'us_core_v311' } }

    it 'converts hash to array' do
      result = instance.thor_hash_to_suite_options_array(hash)
      expect(result.class).to eq(Array)
    end

    it 'returns proper inputs array' do
      result = instance.thor_hash_to_inputs_array(hash)
      expect(result).to eq([{ name: :us_core, value: 'us_core_v311' }])
    end
  end

  describe '#thor_hash_to_inputs_array' do
    let(:hash) { { url: 'https://example.com' } }

    it 'converts hash to array' do
      result = instance.thor_hash_to_inputs_array(hash)
      expect(result.class).to eq(Array)
    end

    it 'returns proper inputs array' do
      result = instance.thor_hash_to_inputs_array(hash)
      expect(result).to eq([{ name: :url, value: 'https://example.com' }])
    end
  end

  describe '#runnable_type' do
    { BasicTestSuite::Suite => :suite, BasicTestSuite::AbcGroup => :group,
      BasicTestSuite::AbcGroup.tests.first => :test }.each do |runnable, type|
      it "can return #{type} type" do
        expect(instance.runnable_type(runnable)).to eq(type)
      end
    end
  end

  describe '#runnable_id_key' do
    { suite: :test_suite_id, group: :test_group_id, test: :test_id }.each do |runnable_type, id_key|
      it "returns proper id key for runnable type #{runnable_type}" do
        allow(instance).to receive(:runnable_type).and_return(runnable_type)
        runnable = case runnable_type
                   when :suite
                     BasicTestSuite::Suite
                   when :group
                     BasicTestSuite::AbcGroup
                   else
                     BasicTestSuite::AbcGroup.tests.first
                   end
        expect(instance.runnable_id_key(runnable)).to eq(id_key)
      end
    end
  end

  describe '#run' do
    let(:suite) { 'dev_validator' }
    let(:session_data_repo) { Inferno::Repositories::SessionData.new }
    let(:test_session) { repo_create(:test_session, test_suite_id: suite.id) }

    let(:success_outcome) do
      {
        outcomes: [{
          issues: []
        }],
        sessionId: ''
      }
    end

    let(:inputs) { { 'url' => 'https://example.com', 'patient_id' => '1' } }

    it 'works on dev_validator suite' do
      stub_request(:post, "#{ENV.fetch('FHIR_RESOURCE_VALIDATOR_URL')}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: success_outcome.to_json)

      stub_request(:get, 'https://example.com/Patient/1')
        .to_return(status: 200, body: FHIR::Patient.new({ name: { given: 'Smith' } }).to_json)

      expect do
        expect { instance.run({ suite:, inputs:, verbose: true }) }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
      end.to output(/.+/).to_stdout
    end
  end
end
