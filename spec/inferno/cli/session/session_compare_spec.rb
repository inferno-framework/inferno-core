require_relative '../../../../lib/inferno/apps/cli/session/session_compare'

RSpec.describe Inferno::CLI::Session::SessionCompare do
  let(:actual_results) do
    File.read(File.join(__dir__, '..', '..', '..', 'fixtures', 'simple_session_results.json'))
  end
  let(:actual_results_parsed) { JSON.parse(actual_results) }
  let(:actual_results_session_id) { actual_results_parsed.first['test_session_id'] }
  let(:actual_results_run_id) { actual_results_parsed.first['test_run_id'] }
  let(:expected_results_session_id) { 'AAAAAAAAA' }
  let(:expected_results_run_id) { '0017d9cc-8c56-41e7-a9b3-529b68e0b526' }
  let(:expected_results) do
    actual_results
      .gsub(actual_results_session_id, expected_results_session_id)
      .gsub(actual_results_run_id, expected_results_run_id)
  end
  let(:expected_results_parsed) { JSON.parse(expected_results) }
  let(:inferno_host) { 'https://inferno.healthit.gov/suites' }

  describe 'when comparing results only' do
    it 'passes when results are equivalent' do
      actual_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{actual_results_session_id}/results"
        ).to_return(status: 200, body: actual_results)
      expected_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{expected_results_session_id}/results"
        ).to_return(status: 200, body: expected_results)

      options = { inferno_base_url: inferno_host, expected_results_session: expected_results_session_id }
      expect do
        expect { described_class.new(actual_results_session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
      end.to output(/.+/).to_stdout
      expect(actual_results_request).to have_been_made.once
      expect(expected_results_request).to have_been_made.once
    end

    it 'fails when results are different' do
      actual_results_parsed.last['result'] = 'fail'
      actual_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{actual_results_session_id}/results"
        ).to_return(status: 200, body: actual_results_parsed.to_json)
      expected_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{expected_results_session_id}/results"
        ).to_return(status: 200, body: expected_results)

      options = { inferno_base_url: inferno_host, expected_results_session: expected_results_session_id }
      expect do
        expect { described_class.new(actual_results_session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output(/.+/).to_stdout
      expect(actual_results_request).to have_been_made.once
      expect(expected_results_request).to have_been_made.once
    end
  end

  describe 'when comparing messages' do
    let(:result_with_messages) do
      {
        messages: [
          {
            message: 'Patient/85: Patient.extension[0].extension[0].value.ofType(Coding): something is wrong',
            type: 'info'
          },
          {
            message: 'Patient/85: Patient.extension[1].extension[0].value.ofType(Coding): also wrong',
            type: 'info'
          },
          {
            message: 'Patient/85: Patient.identifier[2].type: and also wrong',
            type: 'warning'
          }
        ],
        result: 'pass',
        test_id: 'us_core_v610-us_core_v610_fhir_api-us_core_v610_patient-us_core_v610_patient_validation_test'
      }
    end

    it 'passes when no messages' do
      result_with_messages[:messages] = []
      actual_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{actual_results_session_id}/results"
        ).to_return(status: 200, body: [result_with_messages].to_json)
      expected_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{expected_results_session_id}/results"
        ).to_return(status: 200, body: [result_with_messages].to_json)

      options = { inferno_base_url: inferno_host, expected_results_session: expected_results_session_id,
                  compare_messages: true }
      expect do
        expect { described_class.new(actual_results_session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
      end.to output(/.+/).to_stdout
      expect(actual_results_request).to have_been_made.once
      expect(expected_results_request).to have_been_made.once
    end

    it 'passes when the same messages' do
      actual_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{actual_results_session_id}/results"
        ).to_return(status: 200, body: [result_with_messages].to_json)
      expected_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{expected_results_session_id}/results"
        ).to_return(status: 200, body: [result_with_messages].to_json)

      options = { inferno_base_url: inferno_host, expected_results_session: expected_results_session_id,
                  compare_messages: true }
      expect do
        expect { described_class.new(actual_results_session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
      end.to output(/.+/).to_stdout
      expect(actual_results_request).to have_been_made.once
      expect(expected_results_request).to have_been_made.once
    end

    it 'pass when different numbers of messages but messages are not being compared' do
      actual_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{actual_results_session_id}/results"
        ).to_return(status: 200, body: [result_with_messages].to_json)
      result_with_messages[:messages] = []
      expected_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{expected_results_session_id}/results"
        ).to_return(status: 200, body: [result_with_messages].to_json)

      options = { inferno_base_url: inferno_host, expected_results_session: expected_results_session_id,
                  compare_messages: false }
      expect do
        expect { described_class.new(actual_results_session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
      end.to output(/.+/).to_stdout
      expect(actual_results_request).to have_been_made.once
      expect(expected_results_request).to have_been_made.once
    end

    it 'fails when different numbers of messages' do
      actual_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{actual_results_session_id}/results"
        ).to_return(status: 200, body: [result_with_messages].to_json)
      result_with_messages[:messages] = []
      expected_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{expected_results_session_id}/results"
        ).to_return(status: 200, body: [result_with_messages].to_json)

      options = { inferno_base_url: inferno_host, expected_results_session: expected_results_session_id,
                  compare_messages: true }
      expect do
        expect { described_class.new(actual_results_session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output(/.+/).to_stdout
      expect(actual_results_request).to have_been_made.once
      expect(expected_results_request).to have_been_made.once
    end

    it 'fails when the same number of messages, but different ones' do
      actual_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{actual_results_session_id}/results"
        ).to_return(status: 200, body: [result_with_messages].to_json)
      result_with_messages[:messages].last['message'] = 'different'
      expected_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{expected_results_session_id}/results"
        ).to_return(status: 200, body: [result_with_messages].to_json)

      options = { inferno_base_url: inferno_host, expected_results_session: expected_results_session_id,
                  compare_messages: true }
      expect do
        expect { described_class.new(actual_results_session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output(/.+/).to_stdout
      expect(actual_results_request).to have_been_made.once
      expect(expected_results_request).to have_been_made.once
    end

    it 'fails when the same messages, but different type' do
      actual_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{actual_results_session_id}/results"
        ).to_return(status: 200, body: [result_with_messages].to_json)
      result_with_messages[:messages].last['type'] = 'error'
      expected_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{expected_results_session_id}/results"
        ).to_return(status: 200, body: [result_with_messages].to_json)

      options = { inferno_base_url: inferno_host, expected_results_session: expected_results_session_id,
                  compare_messages: true }
      expect do
        expect { described_class.new(actual_results_session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output(/.+/).to_stdout
      expect(actual_results_request).to have_been_made.once
      expect(expected_results_request).to have_been_made.once
    end

    it 'fails when the same messages, but in a different order' do
      actual_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{actual_results_session_id}/results"
        ).to_return(status: 200, body: [result_with_messages].to_json)
      result_with_messages[:messages] =
        [result_with_messages[:messages][1], result_with_messages[:messages][0], result_with_messages[:messages][2]]
      expected_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{expected_results_session_id}/results"
        ).to_return(status: 200, body: [result_with_messages].to_json)

      options = { inferno_base_url: inferno_host, expected_results_session: expected_results_session_id,
                  compare_messages: true }
      expect do
        expect { described_class.new(actual_results_session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output(/.+/).to_stdout
      expect(actual_results_request).to have_been_made.once
      expect(expected_results_request).to have_been_made.once
    end
  end

  describe 'when comparing result_message' do
    let(:result_with_result_messages) do
      {
        result_message: 'more details',
        result: 'pass',
        test_id: 'us_core_v610-us_core_v610_fhir_api-us_core_v610_patient-us_core_v610_patient_validation_test'
      }
    end

    it 'passes when no result_message' do
      result_with_result_messages.delete(:result_message)
      actual_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{actual_results_session_id}/results"
        ).to_return(status: 200, body: [result_with_result_messages].to_json)
      expected_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{expected_results_session_id}/results"
        ).to_return(status: 200, body: [result_with_result_messages].to_json)

      options = { inferno_base_url: inferno_host, expected_results_session: expected_results_session_id,
                  compare_result_message: true }
      expect do
        expect { described_class.new(actual_results_session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
      end.to output(/.+/).to_stdout
      expect(actual_results_request).to have_been_made.once
      expect(expected_results_request).to have_been_made.once
    end

    it 'passes when the same result_message' do
      actual_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{actual_results_session_id}/results"
        ).to_return(status: 200, body: [result_with_result_messages].to_json)
      expected_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{expected_results_session_id}/results"
        ).to_return(status: 200, body: [result_with_result_messages].to_json)

      options = { inferno_base_url: inferno_host, expected_results_session: expected_results_session_id,
                  compare_result_message: true }
      expect do
        expect { described_class.new(actual_results_session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
      end.to output(/.+/).to_stdout
      expect(actual_results_request).to have_been_made.once
      expect(expected_results_request).to have_been_made.once
    end

    it 'fails when one has result_message and the other does not' do
      actual_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{actual_results_session_id}/results"
        ).to_return(status: 200, body: [result_with_result_messages].to_json)
      result_with_result_messages.delete(:result_message)
      expected_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{expected_results_session_id}/results"
        ).to_return(status: 200, body: [result_with_result_messages].to_json)

      options = { inferno_base_url: inferno_host, expected_results_session: expected_results_session_id,
                  compare_result_message: true }
      expect do
        expect { described_class.new(actual_results_session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output(/.+/).to_stdout
      expect(actual_results_request).to have_been_made.once
      expect(expected_results_request).to have_been_made.once
    end

    it 'fails when result_message is different' do
      actual_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{actual_results_session_id}/results"
        ).to_return(status: 200, body: [result_with_result_messages].to_json)
      result_with_result_messages[:result_message] = 'different'
      expected_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{expected_results_session_id}/results"
        ).to_return(status: 200, body: [result_with_result_messages].to_json)

      options = { inferno_base_url: inferno_host, expected_results_session: expected_results_session_id,
                  compare_result_message: true }
      expect do
        expect { described_class.new(actual_results_session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output(/.+/).to_stdout
      expect(actual_results_request).to have_been_made.once
      expect(expected_results_request).to have_been_made.once
    end

    it 'passes when result_message is different but it is not being checked' do
      actual_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{actual_results_session_id}/results"
        ).to_return(status: 200, body: [result_with_result_messages].to_json)
      result_with_result_messages[:result_message] = 'different'
      expected_results_request =
        stub_request(
          :get,
          "#{inferno_host}/api/test_sessions/#{expected_results_session_id}/results"
        ).to_return(status: 200, body: [result_with_result_messages].to_json)

      options = { inferno_base_url: inferno_host, expected_results_session: expected_results_session_id,
                  compare_result_message: false }
      expect do
        expect { described_class.new(actual_results_session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
      end.to output(/.+/).to_stdout
      expect(actual_results_request).to have_been_made.once
      expect(expected_results_request).to have_been_made.once
    end
  end
end
