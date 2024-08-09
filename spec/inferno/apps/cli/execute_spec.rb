require_relative '../../../../lib/inferno/apps/cli/execute'

RSpec.describe Inferno::CLI::Execute do # rubocop:disable RSpec/FilePath
  let(:instance) { described_class.new }

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
      stubbed_instance = instance
      allow(stubbed_instance).to receive(:options).and_return({ inputs: inputs_hash })
      test_session_inst = test_session

      result = stubbed_instance.create_params(test_session_inst, test_suite)
      expect(result).to eq({ test_session_id: test_session.id, test_suite_id: test_suite.id, inputs: inputs_array })
    end
  end

  describe '#serialize' do
    let(:test_results) { create_list(:result, 2) }

    it 'handles an array of test results without raising exception' do
      expect { instance.serialize(test_results) }.to_not raise_error(StandardError)
    end

    it 'returns legit JSON' do
      expect { JSON.parse(instance.serialize(test_results)) }.to_not raise_error(JSON::ParserError)
      expect { JSON.parse(instance.serialize(test_results)) }.to_not raise_error(JSON::NestingError)
      expect { JSON.parse(instance.serialize(test_results)) }.to_not raise_error(TypeError)
    end
  end

  describe '#verbose_print' do
    it 'outputs when verbose is true' do
      stubbed_instance = instance
      allow(stubbed_instance).to receive(:options).and_return({ verbose: true })

      expect { stubbed_instance.verbose_print('Lorem') }.to output(/Lorem/).to_stdout
    end

    it 'does not output when verbose is false' do
      stubbed_instance = instance
      allow(stubbed_instance).to receive(:options).and_return({ verbose: false })

      expect { stubbed_instance.verbose_print('Lorem') }.to_not output(/.+/).to_stdout
    end
  end

  describe '#verbose_puts' do
    it 'has output ending with \n with when verbose is true' do
      stubbed_instance = instance
      allow(stubbed_instance).to receive(:options).and_return({ verbose: true })

      expect { stubbed_instance.verbose_puts('Lorem') }.to output(/Lorem\n/).to_stdout
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

    it 'includes all characters case-insensitive' do
      messages = test_result.messages
      formatted_string = instance.format_messages(test_result)

      messages.each do |message|
        expect(formatted_string.upcase).to include message.message.upcase
      end
    end
  end

  describe '#format_requests' do
    let(:test_result) { repo_create(:result, request_count: 10) }
    let(:instance) { described_class.new }

    it 'includes all status codes' do
      requests = test_result.requests
      formatted_string = instance.format_requests(test_result)

      requests.each do |request|
        expect(formatted_string.upcase).to include request.status.to_s.upcase
      end
    end
  end

  describe '#format_inputs' do
    let(:inputs) { [{ name: :url, value: 'https://example.com' }] }
    let(:test_result) { create(:result, input_json: JSON.generate(inputs)) }

    it 'includes all values' do
      formatted_string = instance.format_inputs(test_result)
      inputs.each do |input_element|
        expect(formatted_string).to include input_element[:value]
      end
    end
  end

  describe '#format_outputs' do
    let(:outputs) { [{ name: :token, value: 'SAMPLE_OUTPUT' }] }
    let(:test_result) { create(:result, output_json: JSON.generate(outputs)) }

    it 'includes all values' do
      formatted_string = instance.format_outputs(test_result)
      outputs.each do |output_element|
        expect(formatted_string).to include output_element[:value]
      end
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

    it 'outputs something with 10 random results' do
      stubbed_instance = instance
      allow(stubbed_instance).to receive(:options).and_return({ verbose: false })
      expect { stubbed_instance.print_color_results(results) }.to output(/.+/).to_stdout
    end

    it 'outputs something with verbose true' do
      stubbed_instance = instance
      allow(stubbed_instance).to receive(:options).and_return({ verbose: true })
      expect { stubbed_instance.print_color_results(results) }.to output(/.+/).to_stdout
    end
  end
end
