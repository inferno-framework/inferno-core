RSpec.describe Inferno::Repositories::Results do
  let(:repo) { described_class.new }
  let(:test_suite) { test_run.test_suite }
  let(:test_session) { test_run.test_session }
  let(:test_run) { repo_create(:test_run) }
  let(:result_params) do
    {
      test_session_id: test_session.id,
      test_run_id: test_run.id,
      test_suite_id: test_suite.id,
      result: 'pass'
    }
  end
  let(:messages) do
    [
      {
        message: 'WARNING',
        type: 'warning'
      },
      {
        message: 'ERROR',
        type: 'error'
      }
    ]
  end
  let(:request_definition) do
    {
      verb: 'get',
      url: 'http://example.com',
      direction: 'outgoing',
      status: 200,
      request_body: 'REQUEST_BODY',
      response_body: 'RESPONSE_BODY',
      request_headers: [{ name: 'REQUEST_HEADER_NAME', value: 'REQUEST_HEADER_VALUE', type: 'request' }],
      response_headers: [{ name: 'RESPONSE_HEADER_NAME', value: 'RESPONSE_HEADER_VALUE', type: 'response' }]
    }
  end

  describe '#create' do
    it 'persists a result' do
      result = repo.create(result_params)

      result_params.each do |key, value|
        expect(result.send(key)).to eq(value)
      end
    end

    it 'persists messages if present' do
      result = repo.create(result_params.merge(messages: messages))

      persisted_messages = Inferno::Repositories::Messages.new.messages_for_result(result.id)
      expect(persisted_messages.length).to eq(messages.length)
    end

    it 'persists requests if present' do
      result = repo.create(result_params.merge(requests: [request_definition]))

      requests = Inferno::Repositories::Requests.new.requests_for_result(result.id)
      expect(requests.length).to eq(1)
    end

    it 'raises an error if the result is invalid' do
      invalid_params = result_params.merge(result: 'abc')

      expect { repo.create(invalid_params) }.to raise_error(Sequel::ValidationFailed, /abc/)
    end

    it 'raises an error if a message is invalid' do
      invalid_params = result_params.merge(messages: [{ message: 'INVALID' }])

      expect { repo.create(invalid_params) }.to raise_error(Sequel::ValidationFailed)
    end
  end
end
