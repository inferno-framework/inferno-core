RSpec.describe Inferno::Repositories::Results do
  let(:repo) { described_class.new }
  let(:test_suite) { test_run.test_suite }
  let(:test_session) { test_run.test_session }
  let(:test_run) { repo_create(:test_run) }
  let(:base_result_params) do
    {
      test_session_id: test_session.id,
      test_run_id: test_run.id,
      result: 'pass'
    }
  end
  let(:result_params) { base_result_params.merge(test_suite_id: test_suite.id) }
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
      request = Inferno::Repositories::Requests.new.create(request_definition)
      result = repo.create(result_params.merge(requests: [request]))

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

  describe '#current_results_for_test_session' do
    let(:test_group) { test_suite.groups.first }
    let(:test) { test_group.tests.first }

    it 'returns only the most recent result for each test, group, and suite' do
      repo_create(:result, result_params)
      repo_create(:result, base_result_params.merge(runnable: test_group.reference_hash))
      repo_create(:result, base_result_params.merge(runnable: test.reference_hash))
      sleep 0.1
      suite_result = repo_create(:result, result_params)
      group_result = repo_create(:result, base_result_params.merge(runnable: test_group.reference_hash))
      test_result = repo_create(:result, base_result_params.merge(runnable: test.reference_hash))

      results = repo.current_results_for_test_session(test_session.id)
      expect(results.length).to eq(3)

      result_ids = results.map(&:id)
      expected_ids = [suite_result, group_result, test_result].map(&:id)

      expect(result_ids).to match_array(expected_ids)
    end
  end

  describe '#current_results_for_test_session_and_runnables' do
    let(:test_group) { test_suite.groups.first }
    let(:test) { test_group.tests.first }

    it 'returns only the most recent result for each test, group, and suite' do
      repo_create(:result, base_result_params.merge(runnable: test_group.reference_hash))
      repo_create(:result, base_result_params.merge(runnable: test.reference_hash))
      sleep 0.1
      group_result = repo_create(:result, base_result_params.merge(runnable: test_group.reference_hash))
      test_result = repo_create(:result, base_result_params.merge(runnable: test.reference_hash))

      results = repo.current_results_for_test_session_and_runnables(test_session.id, test_group.children)
      expect(results.length).to eq(1)
      expect(results.first.id).to eq(test_result.id)

      results = repo.current_results_for_test_session_and_runnables(test_session.id, test_suite.children)
      expect(results.length).to eq(1)
      expect(results.first.id).to eq(group_result.id)
    end
  end
end
