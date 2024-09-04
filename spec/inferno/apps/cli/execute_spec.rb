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

  [
    { suite: 'basic' },
    { group: 'BasicTestSuite::AbcGroup' },
    { test: 'BasicTestSuite::AbcGroup-demo_test' }
  ].each do |given_options|
    describe '#runnable' do
      it "sets runnable to #{given_options.keys.first} entity" do
        allow(instance).to receive(:options).and_return(given_options)
        klass = case given_options.keys.first
                when :suite
                  Inferno::TestSuite
                when :group
                  Inferno::TestGroup
                else
                  Inferno::Test
                end

        expect(instance.runnable).to be < klass
      end
    end

    describe '#runnable_type' do
      it "sets runnable_type to #{given_options.keys.first}" do
        allow(instance).to receive(:options).and_return(given_options)

        expect(instance.runnable_type).to eq(given_options.keys.first.to_s)
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
