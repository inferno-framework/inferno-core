require 'cgi'
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
  let(:session_details_body) do
    {
      id: actual_results_session_id,
      test_suite_id: 'demo',
      test_suite: {
        id: 'demo',
        short_id: '1',
        test_groups: [
          {
            id: 'demo-wait_group',
            short_id: '1.1',
            tests: [
              { id: 'demo-wait_group-Test01', short_id: '1.1.01' },
              { id: 'demo-wait_group-Test02', short_id: '1.1.02' },
              { id: 'demo-wait_group-Test03', short_id: '1.1.03' }
            ]
          }
        ],
        tests: []
      }
    }.to_json
  end

  before do
    stub_request(:get, "#{inferno_host}/api/test_sessions/#{actual_results_session_id}")
      .to_return(status: 200, body: session_details_body)
  end

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

    it 'succeeds when the same messages, but in a different order' do
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
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
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

  describe 'when using normalized_strings' do
    def stub_results(actual:, expected:)
      stub_request(:get, "#{inferno_host}/api/test_sessions/#{actual_results_session_id}/results")
        .to_return(status: 200, body: [actual].to_json)
      stub_request(:get, "#{inferno_host}/api/test_sessions/#{expected_results_session_id}/results")
        .to_return(status: 200, body: [expected].to_json)
    end

    let(:test_result_base) { { result: 'pass', test_id: 'test-id-1' } }
    let(:server_a) { 'http://server-a.example.com' }
    let(:server_b) { 'http://server-b.example.com' }

    it 'passes when result_messages differ only in a normalized string' do
      actual = test_result_base.merge(result_message: "Issuer must be #{server_b}")
      expected = test_result_base.merge(result_message: "Issuer must be #{server_a}")
      stub_results(actual:, expected:)

      options = { inferno_base_url: inferno_host, expected_results_session: expected_results_session_id,
                  compare_result_message: true, normalized_strings: [server_a, server_b] }
      expect do
        expect { described_class.new(actual_results_session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
      end.to output(/.+/).to_stdout
    end

    it 'passes when result_messages contain the URL-encoded form of a normalized string' do
      actual = test_result_base.merge(result_message: "Redirect: #{CGI.escape(server_b)}/callback")
      expected = test_result_base.merge(result_message: "Redirect: #{CGI.escape(server_a)}/callback")
      stub_results(actual:, expected:)

      options = { inferno_base_url: inferno_host, expected_results_session: expected_results_session_id,
                  compare_result_message: true, normalized_strings: [server_a, server_b] }
      expect do
        expect { described_class.new(actual_results_session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
      end.to output(/.+/).to_stdout
    end

    it 'fails when result_messages differ in a way not covered by the normalized strings' do
      actual = test_result_base.merge(result_message: "Issuer must be #{server_b}/extra-path")
      expected = test_result_base.merge(result_message: "Issuer must be #{server_a}")
      stub_results(actual:, expected:)

      options = { inferno_base_url: inferno_host, expected_results_session: expected_results_session_id,
                  compare_result_message: true, normalized_strings: [server_a, server_b] }
      expect do
        expect { described_class.new(actual_results_session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 3)))
      end.to output(/.+/).to_stdout
    end

    it 'applies to messages as well as result_message' do
      actual = test_result_base.merge(messages: [{ message: "Token issuer: #{server_b}", type: 'info' }])
      expected = test_result_base.merge(messages: [{ message: "Token issuer: #{server_a}", type: 'info' }])
      stub_results(actual:, expected:)

      options = { inferno_base_url: inferno_host, expected_results_session: expected_results_session_id,
                  compare_messages: true, normalized_strings: [server_a, server_b] }
      expect do
        expect { described_class.new(actual_results_session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
      end.to output(/.+/).to_stdout
    end

    it 'passes when messages only differ in normalized strings but would sort differently without normalization' do
      # 'aaa_server' sorts before the fixed message alphabetically ('a' < 'm')
      # 'zzz_server' sorts after the fixed message alphabetically ('z' > 'm')
      # Both normalize to '<NORMALIZED>' which sorts before the fixed message ('<' < 'm'),
      # so normalization-based sorting produces the same order for expected and actual.
      # Without normalization in sorting, the pairs are mismatched and the comparison fails.
      fixed_msg = 'Msg: m_something'
      expected = test_result_base.merge(messages: [
                                          { message: 'Msg: aaa_server/path', type: 'info' },
                                          { message: fixed_msg, type: 'info' }
                                        ])
      actual = test_result_base.merge(messages: [
                                        { message: 'Msg: zzz_server/path', type: 'info' },
                                        { message: fixed_msg, type: 'info' }
                                      ])
      stub_results(actual:, expected:)

      options = { inferno_base_url: inferno_host, expected_results_session: expected_results_session_id,
                  compare_messages: true, normalized_strings: ['aaa_server', 'zzz_server'] }
      expect do
        expect { described_class.new(actual_results_session_id, options).run }
          .to raise_error(an_instance_of(SystemExit).and(having_attributes(status: 0)))
      end.to output(/.+/).to_stdout
    end
  end

  describe '.results_for_storage' do
    let(:results) do
      [
        {
          'id' => 'result-id', 'created_at' => 'now', 'test_id' => 'test-1', 'test_session_id' => 'abc123',
          'test_run_id' => 'run-1', 'result' => 'fail', 'result_message' => 'failed for session abc123',
          'inputs' => [{ 'name' => 'url', 'value' => 'http://x/abc123', 'type' => 'text', 'title' => 'URL' },
                       { 'name' => 'auth', 'value' => { 'token' => 'abc123' }, 'type' => 'auth_info' },
                       { 'name' => 'big', 'value' => "Input is too large to display, please visit\nhttp://x/1\n" }],
          'outputs' => [{ 'name' => 'token', 'value' => 'abc', 'type' => 'text' }],
          'messages' => [{ 'id' => 'message-id', 'type' => 'error', 'message' => 'bad abc123', 'result_id' => 'r' }],
          'requests' => [{ 'id' => 'request-id', 'direction' => 'outgoing', 'verb' => 'get',
                           'url' => 'http://x/abc123?q=1', 'status' => 200, 'index' => 1, 'timestamp' => 'now' }]
        },
        { 'test_group_id' => 'group-1', 'result' => 'pass', 'messages' => [], 'outputs' => [] }
      ]
    end

    it 'keeps only compared fields, without test_session_id' do
      expect(described_class.results_for_storage(results)).to eq(
        [
          {
            'test_id' => 'test-1', 'result' => 'fail', 'result_message' => 'failed for session abc123',
            'inputs' => [{ 'name' => 'url', 'value' => 'http://x/abc123' },
                         { 'name' => 'auth', 'value' => '{"token":"abc123"}' },
                         { 'name' => 'big', 'value' => '<too large to compare>' }],
            'outputs' => [{ 'name' => 'token', 'value' => 'abc' }],
            'messages' => [{ 'type' => 'error', 'message' => 'bad abc123' }],
            'requests' => [{ 'direction' => 'outgoing', 'verb' => 'get', 'url' => 'http://x/abc123?q=1',
                             'status' => 200 }]
          },
          { 'test_group_id' => 'group-1', 'result' => 'pass' }
        ]
      )
    end

    it 'applies normalized strings to result messages, messages, request URLs, and input and output values' do
      normalized_strings = [{ 'pattern' => 'abc123', 'replacement' => '<s.session_id>' }]
      stored = described_class.results_for_storage(results, normalized_strings).first

      expect(stored['result_message']).to eq('failed for session <s.session_id>')
      expect(stored['messages'].first['message']).to eq('bad <s.session_id>')
      expect(stored['requests'].first['url']).to eq('http://x/<s.session_id>?q=1')
      expect(stored['inputs'].map { |input| input['value'] })
        .to eq(['http://x/<s.session_id>', '{"token":"<s.session_id>"}', '<too large to compare>'])
    end

    it 'stores results that compare equal to the unnormalized results' do
      normalized_strings = [{ 'pattern' => 'abc123', 'replacement' => '<s.session_id>' }, '/q=\\d+/']
      stored = described_class.results_for_storage(results, normalized_strings)
      options = { compare_messages: true, compare_result_message: true, compare_requests: true, compare_io: true,
                  normalized_strings: }

      results.zip(stored).each do |actual, expected|
        id = actual['test_id'] || actual['test_group_id']
        expect(described_class::ComparedTestResult.new(id, expected, actual, options).same_result?).to be(true)
      end
    end

    it 'does not change results that are already stored' do
      normalized_strings = [{ 'pattern' => 'abc123', 'replacement' => '<s.session_id>' }, '/q=\\d+/']
      stored = described_class.results_for_storage(results, normalized_strings)
      expect(described_class.results_for_storage(stored, normalized_strings)).to eq(stored)
    end
  end

  describe '#save_actual_results_to_file' do
    it 'writes the actual results in stored form next to the expected results file' do
      Dir.mktmpdir do |dir|
        expected_file = File.join(dir, 'script_expected.json')
        normalized_strings = [{ 'pattern' => actual_results_session_id, 'replacement' => '<s.session_id>' }]
        compare = described_class.new(actual_results_session_id, { expected_results_file: expected_file,
                                                                   normalized_strings: })
        allow(compare).to receive(:session_results).and_return(actual_results_parsed)

        compare.save_actual_results_to_file

        written = Dir.glob(File.join(dir, 'script_actual_results_*.json'))
        expect(written.length).to eq(1)
        expect(JSON.parse(File.read(written.first)))
          .to eq(described_class.results_for_storage(actual_results_parsed, normalized_strings))
        expect(File.read(written.first)).to_not include(actual_results_session_id)
      end
    end
  end

  describe described_class::ComparedTestResult do
    let(:base_result) do
      { 'result' => 'pass', 'test_id' => 'test-id-1' }
    end

    def make_result(messages)
      base_result.merge('messages' => messages)
    end

    def compared(expected, actual, options = {})
      described_class.new('test-id-1', expected, actual, options)
    end

    describe '#format_messages_for_csv' do
      context 'when messages repeat' do
        it 'collapses consecutive identical messages into a single line with a count' do
          msg = { 'message' => 'something wrong', 'type' => 'warning' }
          result = make_result([msg, msg, msg])
          r = compared(result, result)
          expect(r.format_messages_for_csv(result)).to eq('(3) - (warning) "something wrong"')
        end

        it 'does not add a count for a single occurrence' do
          msg = { 'message' => 'something wrong', 'type' => 'warning' }
          result = make_result([msg])
          r = compared(result, result)
          expect(r.format_messages_for_csv(result)).to eq('- (warning) "something wrong"')
        end

        it 'collapses runs independently' do
          msg_a = { 'message' => 'aaa issue', 'type' => 'info' }
          msg_b = { 'message' => 'bbb issue', 'type' => 'info' }
          result = make_result([msg_a, msg_a, msg_b, msg_b, msg_b])
          r = compared(result, result)
          expect(r.format_messages_for_csv(result)).to eq("(2) - (info) \"aaa issue\"\n(3) - (info) \"bbb issue\"")
        end
      end

      context 'with only_different_messages option' do
        it 'hides matching messages' do
          matching = { 'message' => 'fine', 'type' => 'info' }
          extra    = { 'message' => 'aaa extra', 'type' => 'info' }
          expected = make_result([matching])
          actual   = make_result([extra, matching])
          r = compared(expected, actual, { only_different_messages: true })
          expect(r.format_messages_for_csv(expected)).to eq('')
          expect(r.format_messages_for_csv(actual)).to eq('! (info) "aaa extra"')
        end

        it 'still shows mismatched messages' do
          msg_a = { 'message' => 'aaa message', 'type' => 'info' }
          msg_b = { 'message' => 'bbb message', 'type' => 'info' }
          expected = make_result([msg_a])
          actual   = make_result([msg_b])
          r = compared(expected, actual, { only_different_messages: true })
          expect(r.format_messages_for_csv(expected)).to eq('! (info) "aaa message"')
          expect(r.format_messages_for_csv(actual)).to eq('! (info) "bbb message"')
        end
      end
    end

    describe 'request comparison' do
      def request(url, direction: 'outgoing', verb: 'get', status: 200)
        { 'id' => SecureRandom.uuid, 'direction' => direction, 'verb' => verb, 'url' => url,
          'status' => status, 'timestamp' => Time.now.iso8601, 'index' => rand(1000) }
      end

      def with_requests(*requests)
        base_result.merge('requests' => requests)
      end

      let(:options) { { compare_requests: true } }

      it 'matches when requests differ only in id, index, and timestamp' do
        expected = with_requests(request('http://localhost:4567/inferno/custom/demo/resume?xyz=abc'))
        actual = with_requests(request('http://localhost:4567/inferno/custom/demo/resume?xyz=abc'))
        expect(compared(expected, actual, options).same_result?).to be(true)
      end

      it 'does not match when only the host differs unless the host is normalized' do
        expected = with_requests(request('http://localhost:4567/inferno/custom/demo/resume'))
        actual = with_requests(request('https://inferno.example.com/inferno/custom/demo/resume'))
        normalizing_options = options.merge(normalized_strings: ['/https?:\/\/[^\/]+/'])
        expect(compared(expected, actual, options).same_result?).to be(false)
        expect(compared(expected, actual, normalizing_options).same_result?).to be(true)
      end

      it 'matches regardless of request order' do
        first = request('http://server/fhir/Patient/1')
        second = request('http://server/fhir/Patient/2')
        expect(compared(with_requests(first, second), with_requests(second, first), options).same_result?)
          .to be(true)
      end

      it 'does not match when a request is missing' do
        expected = with_requests(request('http://server/fhir/Patient/1'), request('http://server/fhir/Patient/2'))
        actual = with_requests(request('http://server/fhir/Patient/1'))
        expect(compared(expected, actual, options).same_result?).to be(false)
      end

      it 'does not match when a request is repeated' do
        expected = with_requests(request('http://server/fhir/Patient/1'))
        actual = with_requests(request('http://server/fhir/Patient/1'), request('http://server/fhir/Patient/1'))
        expect(compared(expected, actual, options).same_result?).to be(false)
      end

      it 'does not match when the URL, verb, direction, or status differ' do
        expected = with_requests(request('http://server/fhir/Patient?name=a'))
        [
          request('http://server/fhir/Observation?name=a'),
          request('http://server/fhir/Patient?name=b'),
          request('http://server/fhir/Patient?name=a', verb: 'post'),
          request('http://server/fhir/Patient?name=a', direction: 'incoming'),
          request('http://server/fhir/Patient?name=a', status: 404)
        ].each do |different|
          expect(compared(expected, with_requests(different), options).same_result?).to be(false)
        end
      end

      it 'applies normalized strings to the URL' do
        expected = with_requests(request('http://server/redirect?code=abc123&state=1'))
        actual = with_requests(request('http://server/redirect?code=xyz789&state=1'))
        normalizing_options = options.merge(normalized_strings: ['/code=[a-z0-9]+/'])
        expect(compared(expected, actual, options).same_result?).to be(false)
        expect(compared(expected, actual, normalizing_options).same_result?).to be(true)
      end

      it 'ignores requests when compare_requests is not set' do
        expected = with_requests(request('http://server/fhir/Patient/1'))
        expect(compared(expected, with_requests, {}).same_result?).to be(true)
      end

      it 'treats a result without requests the same as one with no requests' do
        expect(compared(base_result, with_requests, options).same_result?).to be(true)
      end

      it 'formats requests for CSV, marking mismatches' do
        expected = with_requests(request('http://server/fhir/Patient/1'), request('http://server/fhir/Patient/2'))
        actual = with_requests(request('http://server/fhir/Patient/1', status: 500),
                               request('http://server/fhir/Patient/2'))
        r = compared(expected, actual, options)
        expect(r.format_unordered_comparisons_for_csv(r.request_comparisons, :expected))
          .to eq("! outgoing GET http://server/fhir/Patient/1 200\n- outgoing GET http://server/fhir/Patient/2 200")
        expect(r.format_unordered_comparisons_for_csv(r.request_comparisons, :actual))
          .to eq("! outgoing GET http://server/fhir/Patient/1 500\n- outgoing GET http://server/fhir/Patient/2 200")
        expect(r.comparison_csv_row.last(3).first).to be(true)
      end

      it 'hides matching requests in CSV with only_different_messages' do
        expected = with_requests(request('http://server/fhir/Patient/1'), request('http://server/fhir/Patient/2'))
        actual = with_requests(request('http://server/fhir/Patient/2'))
        r = compared(expected, actual, options.merge(only_different_messages: true))
        expect(r.format_unordered_comparisons_for_csv(r.request_comparisons, :expected))
          .to eq('! outgoing GET http://server/fhir/Patient/1 200')
        expect(r.format_unordered_comparisons_for_csv(r.request_comparisons, :actual)).to eq('')
      end
    end

    describe 'input and output comparison' do
      def io(name, value)
        { 'name' => name, 'value' => value, 'type' => 'text' }
      end

      def with_io(inputs: [], outputs: [])
        base_result.merge('inputs' => inputs, 'outputs' => outputs)
      end

      let(:options) { { compare_io: true } }

      it 'matches when names and values match, regardless of order or other fields' do
        expected = with_io(inputs: [io('a', '1'), io('b', '2')], outputs: [io('c', '3')])
        actual = with_io(inputs: [io('b', '2').merge('type' => 'textarea'), io('a', '1')], outputs: [io('c', '3')])
        expect(compared(expected, actual, options).same_result?).to be(true)
      end

      it 'does not match when a value differs, an entry is missing, or an input becomes an output' do
        expected = with_io(inputs: [io('a', '1')], outputs: [io('c', '3')])
        [
          with_io(inputs: [io('a', '2')], outputs: [io('c', '3')]),
          with_io(inputs: [io('a', '1')]),
          with_io(inputs: [io('a', '1'), io('c', '3')])
        ].each do |different|
          expect(compared(expected, different, options).same_result?).to be(false)
        end
      end

      it 'compares non-string values as JSON' do
        expected = with_io(inputs: [io('auth', { 'auth_type' => 'public' })])
        actual = with_io(inputs: [io('auth', '{"auth_type":"public"}')])
        expect(compared(expected, actual, options).same_result?).to be(true)
      end

      it 'applies normalized strings to the values' do
        expected = with_io(outputs: [io('url', 'http://localhost:4567/inferno/resume')])
        actual = with_io(outputs: [io('url', 'https://inferno.example.com/inferno/resume')])
        normalizing_options = options.merge(normalized_strings: ['/https?:\/\/[^\/]+/'])
        expect(compared(expected, actual, options).same_result?).to be(false)
        expect(compared(expected, actual, normalizing_options).same_result?).to be(true)
      end

      it 'compares large values only by being large, since their placeholder link varies by run' do
        large = lambda do |host, result_id|
          "Input is too large to display, please visit\n" \
            "#{host}/api/test_sessions/abc/results/#{result_id}/io/inputs/patient_json\nfor details\n"
        end
        expected = with_io(inputs: [io('patient_json', large.call('http://localhost:4567/inferno', '1111'))])
        actual = with_io(inputs: [io('patient_json', large.call('https://inferno.example.com', '2222'))])
        expect(compared(expected, actual, options).same_result?).to be(true)
        expect(compared(expected, with_io(inputs: [io('patient_json', '{}')]), options).same_result?).to be(false)
      end

      it 'ignores inputs and outputs when compare_io is not set' do
        expected = with_io(inputs: [io('a', '1')])
        expect(compared(expected, with_io, {}).same_result?).to be(true)
      end

      it 'formats inputs and outputs for CSV, marking mismatches' do
        expected = with_io(inputs: [io('a', '1')], outputs: [io('c', '3')])
        actual = with_io(inputs: [io('a', '2')], outputs: [io('c', '3')])
        r = compared(expected, actual, options)
        expect(r.format_unordered_comparisons_for_csv(r.io_comparisons, :expected))
          .to eq("! input a: 1\n- output c: 3")
        expect(r.format_unordered_comparisons_for_csv(r.io_comparisons, :actual))
          .to eq("! input a: 2\n- output c: 3")
        expect(r.comparison_csv_row.last(3).first).to be(true)
      end
    end
  end
end
