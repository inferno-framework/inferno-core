require 'request_helper'

RSpec.describe '/test_runs' do
  let(:router) { Inferno::Web::Router }
  let(:response_fields) { ['id', 'inputs', 'results', 'status', 'test_group_id'] }
  let(:test_suite) { BasicTestSuite::Suite }
  let(:test_group_id) { test_suite.groups.first.id }
  let(:test_session) { test_run.test_session }
  let(:test_run) { repo_create(:test_run, runnable: { test_group_id: test_group_id }) }

  describe 'create' do
    let(:create_path) { router.path(:api_test_runs) }
    let(:test_run_definition) do
      {
        test_session_id: test_session.id,
        test_group_id: test_group_id
      }
    end

    context 'with valid input' do
      it 'renders the test_run json' do
        post_json create_path, test_run_definition

        expect(last_response.status).to eq(200)

        expect(parsed_body).to include(*response_fields)
        expect(parsed_body['id']).to be_present
        expect(parsed_body['test_session_id']).to eq(test_session.id)
      end

      it 'persists inputs to the session data table' do
        session_data_repo = Inferno::Repositories::SessionData.new
        inputs = [
          { name: 'input1', value: 'value1' },
          { name: 'input2', value: 'value2' }
        ]
        test_run_params = test_run_definition.merge(inputs: inputs)

        post_json create_path, test_run_params

        expect(session_data_repo.db.count).to eq(2)

        inputs.each do |input|
          value = session_data_repo.load(test_session_id: test_session.id, name: input[:name])
          expect(value).to eq(input[:value])
        end
      end
    end
  end

  describe 'show' do
    it 'renders the test_run json' do
      get router.path(:api_test_run, id: test_run.id)

      expect(last_response.status).to eq(200)

      expect(parsed_body).to include(*response_fields)
      expect(parsed_body['id']).to eq(test_run.id)
    end
  end

  describe '/:id/results' do
    let(:result) { repo_create(:result, message_count: 2) }
    let(:messages) { result.messages }

    it 'renders the results json' do
      get router.path(:api_test_run_results, test_run_id: result.test_run_id)

      expect(last_response.status).to eq(200)
      expect(parsed_body).to all(include('id', 'result', 'test_run_id', 'test_session_id', 'messages'))
      expect(parsed_body.first['messages'].length).to eq(messages.length)
    end
  end
end
