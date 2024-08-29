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

  describe '#set_runnable!' do
    [{ suite: 'basic' }, { group: 'BasicTestSuite::AbcGroup' },
     { test: 'BasicTestSuite::AbcGroup-demo_test' }].each do |given_options|
      context "with #{given_options.keys.first} option" do
        it 'sets runnable' do
          allow(instance).to receive(:options).and_return(given_options)

          instance.set_runnable!
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

        # TODO: change with new custom getter
        it 'sets runnable_type' do
          allow(instance).to receive(:options).and_return(given_options)

          instance.set_runnable!
          expect(instance.runnable_type).to eq(given_options.keys.first.to_s)
        end
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
      test_session_inst = test_session

      result = instance.create_params(test_session_inst, test_suite)
      expect(result).to eq({ test_session_id: test_session.id, test_suite_id: test_suite.id, inputs: inputs_array })
    end
  end

  describe '#serialize' do
    let(:test_results) { create_list(:result, 2) }

    it 'handles an array of test results without raising exception' do
      expect { instance.serialize(test_results) }.to_not raise_error(StandardError)
    end

    it 'returns valid JSON' do
      expect { JSON.parse(instance.serialize(test_results)) }.to_not raise_error(StandardError)
    end
  end

  describe '#verbose_print' do
    it 'outputs when verbose is true' do
      allow(instance).to receive(:options).and_return({ verbose: true })

      expect { instance.verbose_print('Lorem') }.to output(/Lorem/).to_stdout
    end

    it 'does not output when verbose is false' do
      allow(instance).to receive(:options).and_return({ verbose: false })

      expect { instance.verbose_print('Lorem') }.to_not output(/.+/).to_stdout
    end
  end

  describe '#verbose_puts' do
    it 'has output ending with \n with when verbose is true' do
      allow(instance).to receive(:options).and_return({ verbose: true })

      expect { instance.verbose_puts('Lorem') }.to output(/Lorem\n/).to_stdout
    end
  end

  describe '#format_id' do
    let(:test_suite) { BasicTestSuite::Suite }
    let(:test_group) { BasicTestSuite::AbcGroup }
    let(:test) { test_group.tests.first }

    it 'returns suite id if test result belongs to suite' do
      test_result = create(:result, runnable: { test_suite_id: test_suite.id })

      expect(instance.format_id(test_result)).to eq(test_suite.id)
    end

    it 'returns group id if test result belongs to group' do
      test_result = create(:result, runnable: { test_group_id: test_group.id })

      expect(instance.format_id(test_result)).to eq(test_group.id)
    end

    it 'returns test id if test result belongs to test' do
      test_result = create(:result, runnable: { test_id: test.id })

      expect(instance.format_id(test_result)).to eq(test.id)
    end
  end

  describe '#format_messages' do
    let(:test_result) { repo_create(:result, message_count: 10) }

    it 'includes all characters' do
      messages = test_result.messages
      formatted_string = instance.format_messages(test_result)

      messages.each do |message|
        expect(formatted_string).to include message.message
      end
    end
  end

  describe '#format_requests' do
    let(:test_result) { repo_create(:result, request_count: 10) }

    it 'includes all status codes' do
      requests = test_result.requests
      formatted_string = instance.format_requests(test_result)

      requests.each do |request|
        expect(formatted_string).to include request.status.to_s
      end
    end
  end

  describe '#format_session_data' do
    let(:data) { [{ name: :url, value: 'https://example.com' }, { name: :token, value: 'SAMPLE_OUTPUT' }] }
    let(:test_result) { create(:result, input_json: JSON.generate(data), output_json: JSON.generate(data)) }

    it 'includes all values for input_json' do
      formatted_string = instance.format_session_data(test_result, :input_json)
      data.each do |data_element|
        expect(formatted_string).to include data_element[:value]
      end
    end

    it 'includes all values for output_json' do
      formatted_string = instance.format_session_data(test_result, :output_json)
      data.each do |data_element|
        expect(formatted_string).to include data_element[:value]
      end
    end
  end

  describe '#format_result' do
    Inferno::Entities::Result::RESULT_OPTIONS.each do |result_option|
      it "can format #{result_option} result type" do
        result = create(:result, result: result_option)
        expect { instance.format_result(result) }.to_not raise_error
      end

      it 'includes result type in return value' do
        result = create(:result, result: result_option)
        expect(instance.format_result(result).upcase).to include result_option.upcase
      end
    end
  end

  describe '#print_color_results' do
    let(:results) { create_list(:random_result, 10) }

    it 'outputs something with verbose false' do
      allow(instance).to receive(:options).and_return({ verbose: false })
      expect { instance.print_color_results(results) }.to output(/.+/).to_stdout
    end

    it 'outputs something with verbose true' do
      allow(instance).to receive(:options).and_return({ verbose: true })
      expect { instance.print_color_results(results) }.to output(/.+/).to_stdout
    end
  end

  describe '#print_error_and_exit' do
    let(:mock_error_class) { Class.new(StandardError) }
    let(:mock_error) { mock_error_class.new('mock message') }

    it 'outputs to stderr and exits' do
      expect do
        expect { instance.print_error_and_exit(mock_error, 2) }.to output(/Error/).to_stderr
      end.to raise_error(SystemExit)
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
