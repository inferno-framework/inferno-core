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
    it 'returns an outputter instance' do
      expect(instance.outputter).to be_an_instance_of(Inferno::CLI::Execute::AbstractOutputter)
    end
  end

  describe '#selected_runnables' do
    it 'returns empty array when no short ids given' do
      allow(instance).to receive(:options).and_return({suite: 'basic'})
      expect(instance.selected_runnables).to eq([])
    end

    it 'returns both groups and tests when short ids for both are given' do
      allow(instance).to receive(:options).and_return({suite: 'basic', groups: '1', tests: '1.01'})
      expect(instance.selected_runnables.length).to eq(2)
    end
  end

  # TODO: run_one spec

  describe '#suite' do
    it 'returns the correct Inferno TestSuite entity' do
      allow(instance).to recieve(:options).and_return({suite: 'basic'})
      expect(instance.suite).to eq(BasicTestSuite::Suite)
    end

    it 'raises standard error if no suite provided' do
      expect{ instance.suite }.to raise_error(StandardError)
    end
  end

  describe '#test_run' do
    {suite: BasicTestSuite::Suite, group: BasicTestSuite::AbcGroup, test: BasicTestSuite::Suite.tests.first}.each do |type, runnable|
      it "returns a test run for #{type}" do
        expect(test_run(runnable)).to be_instance_of Inferno::Entities::TestRun
      end
    end
  end

  describe '#test_session' do
    it 'returns test session given suite options' do
      allow(instance).to receive(:options).and_return({suite: 'basic', suite_options: {option: 'a'}})
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
      allow(instance).to receive(:options).and_return({ inputs: inputs_hash })
      allow(instance).to receive(:runnable_type).and_return('suite')

      result = instance.create_params(test_session, test_suite)
      expect(result).to eq({ test_session_id: test_session.id, test_suite_id: test_suite.id, inputs: inputs_array })
    end
  end

  describe '#dispatch_job' do
    it 'supresses output if verbose is false' do
      allow(instance).to receive(:options).and_return({verbose: false})
      allow(instance).to receive(:test_run).and_return(create(:test_run))

      expect{ instance.dispatch_job }.to_not output(/.+/)
    end
  end

  describe '#groups' do
    it 'parses single group by short id' do
      allow(instance).to receive(:options).and_return({suite: 'basic', groups: ['1']})
      expect{ instance.groups }.to eq([BasicTestSuite::AbcGroup])
    end

    it 'parses multiple groups by short id' do
      allow(instance).to receive(:options).and_return({suite: 'basic', groups: ['1', '2']})
      expect{ instance.groups }.to eq([BasicTestSuite::AbcGroup, BasicTestSuite::DefGroup])
    end
  end

  describe '#tests' do
    it 'parses single test by short id' do
      allow(instance).to receive(:options).and_return({suite: 'basic', groups: ['1.01']})
      expect{ instance.groups }.to eq([BasicTestSuite::Suite.tests.first])
    end

=begin # TODO: change to fixture with multiple tests
    it 'parses multiple tests by short id' do
      allow(instance).to receive(:options).and_return({suite: 'basic', groups: ['1.01', '2.01']})
      expect{ instance.groups }.to eq([BasicTestSuite::Suite.tests.first, BasicTestSuite::DefGroup])
    end
=end
  end

  describe '#find_by_short_id!' do
    it 'raises standard error when entity not found by short id' do
      expect { instance.find_by_short_id!(Inferno::Repositories::Tests.new, 'does_not_exist') }.to raise_error(StandardError)
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

  # TODO print_error_and_exit test?

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
    {BasicTestSuite::Suite => :suite, BasicTestSuite::AbcGroup => :group, BasicTestSuite::Suite.tests.first => :test}.each do |runnable, type|
      it "can return #{type} type" do
        expect( instance.runnable_type(runnable) ).to eq(type)
      end
    end
  end

  describe '#runnable_id_key' do
    { suite: :test_suite_id, group: :test_group_id, test: :test_id }.each do |runnable_type, id_key|
      it "returns proper id for runnable type #{runnable_type}" do
        allow(instance).to receive(:runnable_type).and_return(runnable_type)

        expect(instance.runnable_id_key).to eq(id_key)
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
