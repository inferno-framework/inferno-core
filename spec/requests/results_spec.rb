require 'request_helper'
require_relative '../../lib/inferno/apps/web/router'

RSpec.describe '/(test_sessions/test_runs)/:id/results' do
  let(:router) { Inferno::Web::Router }
  let(:response_fields) { ['id', 'inputs', 'results', 'status', 'test_group_id'] }
  let(:test_suite) { BasicTestSuite::Suite }
  let(:test_group_id) { test_suite.groups.first.id }
  let(:test_run) { repo_create(:test_run, runnable: { test_group_id: }) }
  let(:test_session) { test_run.test_session }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let!(:result) do
    repo_create(
      :result,
      message_count: 1,
      request_count: 2,
      test_run_id: test_run.id,
      test_session_id: test_session.id
    )
  end
  let(:requests) { result.requests }

  describe '/test_runs/:test_run_id/results' do
    it 'renders the results json for a test_run' do
      get router.path(:api_test_runs_results, id: test_run.id)

      expect(last_response.status).to eq(200)
      expect(parsed_body.length).to eq(1)

      values_to_validate = result.to_hash.slice(:test_session_id, :test_group_id, :test_run_id, :result)
      values_to_validate.each do |key, value|
        expect(parsed_body.first[key.to_s]).to eq(value)
      end

      messages = parsed_body.first['messages']
      persisted_messages = result.messages

      expect(messages.length).to eq(persisted_messages.length)

      message = messages.first
      persisted_message = persisted_messages.first

      expect(message['message']).to eq(persisted_message.message)
      expect(message['type']).to eq(persisted_message.type)
    end

    it 'includes the indices for request summaries' do
      get router.path(:api_test_runs_results, id: test_run.id)

      expect(last_response.status).to eq(200)
      expect(parsed_body.length).to eq(1)

      serialized_requests = parsed_body.first['requests']

      expect(serialized_requests).to all(include('index'))
      expect(serialized_requests.first['index']).to be_an(Integer)
    end

    it 'sorts the request summaries' do
      get router.path(:api_test_runs_results, id: test_run.id)

      expect(last_response.status).to eq(200)
      expect(parsed_body.length).to eq(1)

      serialized_requests = parsed_body.first['requests']

      expect(serialized_requests.first['index']).to be < serialized_requests.last['index']
    end
  end

  describe '/test_sessions/:test_session_id/results' do
    it 'renders the results json for a test_session' do
      get router.path(:api_test_sessions_results, id: test_session.id)

      expect(last_response.status).to eq(200)
      expect(parsed_body.length).to eq(1)

      values_to_validate = result.to_hash.slice(:test_session_id, :test_group_id, :test_run_id, :result)
      values_to_validate.each do |key, value|
        expect(parsed_body.first[key.to_s]).to eq(value)
      end

      messages = parsed_body.first['messages']
      persisted_messages = result.messages

      expect(messages.length).to eq(persisted_messages.length)

      message = messages.first
      persisted_message = persisted_messages.first

      expect(message['message']).to eq(persisted_message.message)
      expect(message['type']).to eq(persisted_message.type)
    end
  end
end
