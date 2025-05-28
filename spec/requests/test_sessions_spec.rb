require 'request_helper'
require_relative '../../lib/inferno/apps/web/router'
require_relative '../../lib/inferno/apps/web/controllers/test_sessions/create'
require_relative '../../lib/inferno/apps/web/controllers/test_sessions/session_data/apply_preset'

RSpec.describe '/test_sessions' do
  let(:router) { Inferno::Web::Router }
  let(:response_fields) { ['id', 'test_suite_id', 'test_suite'] }
  let(:test_session) { repo_create(:test_session, test_suite_id:) }
  let(:repo) { Inferno::Repositories::TestSessions.new }

  describe 'create' do
    let(:create_path) { router.path(:api_test_sessions_create) }
    let(:input) do
      { test_suite_id: }
    end

    context 'with valid input' do
      let(:test_suite_id) { 'options' }

      it 'renders the test_session json' do
        post_json create_path, input

        expect(last_response.status).to eq(200)

        expect(parsed_body).to include(*response_fields)
        expect(parsed_body['id']).to be_present
        expect(parsed_body['test_suite_id']).to eq(test_suite_id)
      end

      context 'with a preset id' do
        it 'applies the preset' do
          allow_any_instance_of(Inferno::Repositories::TestSessions).to receive(:apply_preset)

          post_json create_path, input.merge(preset_id: 'PRESET_ID')

          expect(last_response.status).to eq(200)
        end
      end

      context 'with suite options' do
        it 'persists the suite options' do
          options = [{ id: 'ig_version', value: '1' }, { id: 'other_option', value: '2' }]
          post_json create_path, input.merge(suite_options: options)

          expect(last_response.status).to eq(200)
          expect(parsed_body['suite_options']).to eq(options.map(&:stringify_keys))

          persisted_session = repo.find(parsed_body['id'])
          expected_options = options.map { |option| Inferno::DSL::SuiteOption.new(option) }

          expect(persisted_session.suite_options).to eq(expected_options)
        end
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
      let(:test_suite_id) { 'basic' }

      it 'renders the test_session json' do
        get router.path(:api_test_sessions_show, id: test_session.id)

        expect(last_response.status).to eq(200)
        expect(parsed_body).to include(*response_fields)
        expect(parsed_body['test_suite_id']).to eq(test_suite_id)
        expect(parsed_body['id']).to eq(test_session.id)
      end
    end

    context 'when the test_session does not exist' do
      it 'renders a 404' do
        get router.path(:api_test_sessions_show, id: SecureRandom.uuid)

        expect(last_response.status).to eq(404)
      end
    end
  end

  describe '/:id/results' do
    let!(:old_result) { repo_create(:result, message_count: 2, created_at: 1.minute.ago, updated_at: 1.minute.ago) }
    let!(:new_result) { repo_create(:result, message_count: 3, test_session_id: old_result.test_session_id) }

    it 'renders the most recent results' do
      get router.path(:api_test_sessions_results, id: new_result.test_session_id)

      expect(last_response.status).to eq(200)
      expect(parsed_body.length).to eq(1)
      expect(parsed_body).to all(include('id', 'result', 'test_run_id', 'test_session_id', 'messages'))
      result = parsed_body.first

      expect(result['id']).to eq(new_result.id)
      expect(result['messages'].length).to eq(new_result.messages.length)
    end

    context 'when all=true' do
      it 'renders all results' do
        get "#{router.path(:api_test_sessions_results, id: new_result.test_session_id)}?all=true"

        expect(last_response.status).to eq(200)
        expect(parsed_body.length).to eq(2)
        expect(parsed_body).to all(include('id', 'result', 'test_run_id', 'test_session_id', 'messages'))

        new_result_json = parsed_body.find { |result| result['id'] == new_result.id }
        old_result_json = parsed_body.find { |result| result['id'] == old_result.id }

        expect(new_result_json['messages'].length).to eq(new_result.messages.length)
        expect(old_result_json['messages'].length).to eq(old_result.messages.length)
      end
    end
  end

  describe '/:id/results/:result_id/io/:type/:name' do
    let(:io_name) { 'request_body' }
    let(:io_value) { { foo: 'bar' } }
    let(:input_json) { [{ 'name' => io_name, 'value' => io_value }].to_json }
    let(:output_json) { [{ 'name' => io_name, 'value' => io_value }].to_json }
    let!(:result) do
      repo_create(
        :result, message_count: 2, input_json:, output_json:,
                 created_at: 1.minute.ago, updated_at: 1.minute.ago
      )
    end

    context 'when retrieving a valid input' do
      it 'returns the input value as JSON' do
        get router.path(
          :api_test_sessions_result_io_value, id: result.test_session_id,
                                              result_id: result.id, type: 'inputs', name: io_name
        )

        expect(last_response.status).to eq(200)
        expect(last_response.content_type).to include('application/json')
        expect(last_response.body).to eq(io_value.to_json)
      end
    end

    context 'when retrieving a valid output' do
      it 'returns the output value as JSON' do
        get router.path(
          :api_test_sessions_result_io_value, id: result.test_session_id,
                                              result_id: result.id, type: 'outputs', name: io_name
        )

        expect(last_response.status).to eq(200)
        expect(last_response.content_type).to include('application/json')
        expect(last_response.body).to eq(io_value.to_json)
      end
    end

    context 'when the input name does not exist' do
      it 'returns 404' do
        get router.path(
          :api_test_sessions_result_io_value, id: result.test_session_id,
                                              result_id: result.id, type: 'inputs', name: 'missing_name'
        )

        expect(last_response.status).to eq(404)
        expect(parsed_body['error']).to match(/not found/i)
      end
    end

    context 'when the type is not "inputs" or "outputs"' do
      it 'returns 400' do
        get router.path(
          :api_test_sessions_result_io_value, id: result.test_session_id,
                                              result_id: result.id, type: 'input', name: io_name
        )

        expect(last_response.status).to eq(400)
        expect(parsed_body['error']).to match(/Must be "inputs" or "outputs"/i)
      end
    end

    context 'when the result is associated with the wrong test session' do
      it 'returns 404' do
        get router.path(
          :api_test_sessions_result_io_value, id: 'wrong_session',
                                              result_id: result.id, type: 'inputs', name: io_name
        )

        expect(last_response.status).to eq(404)
      end
    end

    context 'when value is a plain string' do
      let(:input_value) { 'This is a plain string' }
      let(:input_json) { [{ 'name' => io_name, 'value' => input_value }].to_json }
      let(:string_input_result) do
        repo_create(
          :result, message_count: 2, input_json:,
                   created_at: 1.minute.ago, updated_at: 1.minute.ago
        )
      end

      it 'returns Content-Type text/plain' do
        get router.path(
          :api_test_sessions_result_io_value, id: string_input_result.test_session_id,
                                              result_id: string_input_result.id, type: 'inputs', name: io_name
        )

        expect(last_response.content_type).to include('text/plain')
        expect(last_response.body).to eq(input_value)
      end
    end

    context 'when value is an XML string' do
      let(:input_value) { '<Patient><name>John</name></Patient>' }
      let(:input_json) { [{ 'name' => io_name, 'value' => input_value }].to_json }
      let(:string_input_result) do
        repo_create(
          :result, message_count: 2, input_json:,
                   created_at: 1.minute.ago, updated_at: 1.minute.ago
        )
      end

      it 'returns Content-Type application/xml' do
        get router.path(
          :api_test_sessions_result_io_value, id: string_input_result.test_session_id,
                                              result_id: string_input_result.id, type: 'inputs', name: io_name
        )

        expect(last_response.content_type).to eq('application/xml')
        expect(last_response.body).to eq(input_value)
      end
    end
  end

  describe '/:id/last_test_run' do
    let(:test_suite_id) { 'basic' }

    it 'renders the test_run json for the most recent run' do
      repo_create(
        :test_run,
        test_session_id: test_session.id,
        created_at: 1.minute.ago,
        updated_at: 1.minute.ago
      )
      last_test_run = repo_create(:test_run, test_session_id: test_session.id)
      get router.path(:api_test_sessions_last_test_run, id: test_session.id)

      expect(last_response.status).to eq(200)
      expect(parsed_body['id']).to eq(last_test_run.id)
    end
  end

  describe '/:id/session_data/apply_preset' do
    let(:test_suite_id) { 'demo' }

    context 'when the preset and session exist' do
      it 'applies the preset' do
        allow_any_instance_of(Inferno::Repositories::TestSessions).to receive(:apply_preset)

        path =
          router.path(
            :api_test_sessions_session_data_apply_preset,
            id: test_session.id,
            preset_id: 'demo_preset'
          )

        put path

        expect(last_response.status).to eq(200)
      end
    end

    context 'when the preset does not exist' do
      it 'returns a 404' do
        allow_any_instance_of(Inferno::Repositories::TestSessions).to receive(:apply_preset)

        path =
          router.path(
            :api_test_sessions_session_data_apply_preset,
            id: test_session.id,
            preset_id: SecureRandom.uuid
          )

        put path

        expect(last_response.status).to eq(404)
      end
    end

    context 'when session does notexist' do
      it 'returns a 404' do
        allow_any_instance_of(Inferno::Repositories::TestSessions).to receive(:apply_preset)

        path =
          router.path(
            :api_test_sessions_session_data_apply_preset,
            id: SecureRandom.uuid,
            preset_id: 'demo_preset'
          )

        put path

        expect(last_response.status).to eq(404)
      end
    end
  end
end
