require 'request_helper'

RSpec.describe '/test_sessions' do
  let(:router) { Inferno::Web::Router }
  let(:response_fields) { ['id', 'test_suite_id', 'test_suite'] }
  let(:test_session) { repo_create(:test_session, test_suite_id: test_suite_id) }

  describe 'create' do
    let(:create_path) { router.path(:api_test_sessions) }
    let(:input) do
      { test_suite_id: test_suite_id }
    end

    context 'with valid input' do
      let(:test_suite_id) { 'BasicTestSuite::Suite' }

      it 'renders the test_session json' do
        post_json create_path, input

        expect(last_response.status).to eq(200)

        expect(parsed_body).to include(*response_fields)
        expect(parsed_body['id']).to be_present
        expect(parsed_body['test_suite_id']).to eq(test_suite_id)
      end
    end

    context 'with invalid input' do
      let(:test_suite_id) { '' }

      it 'renders the errors json' do
        post_json create_path, input

        expect(last_response.status).to eq(422)
        expect(parsed_body['errors']).to be_present
      end
    end
  end

  describe 'show' do
    context 'when the test_session exists' do
      let(:test_suite_id) { 'BasicTestSuite::Suite' }

      it 'renders the test_session json' do
        get router.path(:api_test_session, id: test_session.id)

        expect(last_response.status).to eq(200)
        expect(parsed_body).to include(*response_fields)
        expect(parsed_body['test_suite_id']).to eq(test_suite_id)
        expect(parsed_body['id']).to eq(test_session.id)
      end
    end

    context 'when the test_session does not exist' do
      it 'renders a 404' do
        get router.path(:api_test_session, id: SecureRandom.uuid)

        expect(last_response.status).to eq(404)
      end
    end
  end

  describe '/:id/results' do
    let(:result) { repo_create(:result, message_count: 2) }
    let(:messages) { result.messages }

    it 'renders the results json' do
      get router.path(:api_test_session_results, test_session_id: result.test_session_id)

      expect(last_response.status).to eq(200)
      expect(parsed_body).to all(include('id', 'result', 'test_run_id', 'test_session_id', 'messages'))
      expect(parsed_body.first['messages'].length).to eq(messages.length)
    end
  end
end
