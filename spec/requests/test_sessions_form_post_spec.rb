require 'request_helper'
require_relative '../../lib/inferno/apps/web/router'
require_relative '../../lib/inferno/apps/web/controllers/test_session_form_post_controller'

RSpec.describe 'POST /:test_suite_id' do
  let(:router) { Inferno::Web::Router }
  let(:repo) { Inferno::Repositories::TestSessions.new }

  context 'with valid params' do
    let(:test_suite_id) { 'options' }
    let(:session_data_repo) { Inferno::Repositories::SessionData.new }

    it 'redirects the user to the created test session' do
      post router.path(:session_form_post, test_suite_id:)

      expect(last_response.status).to eq(302)

      location = last_response.headers['Location']
      expect(location).to match(%r{\A#{Inferno::Application['base_url']}/#{test_suite_id}/[\d\w]+\z})
    end

    it 'applies supplied options' do
      options =
        {
          ig_version: '1',
          other_option: '2'
        }

      post(
        router.path(:session_form_post, test_suite_id:),
        URI.encode_www_form(options),
        'Content-Type' => 'application/x-www-form-urlencoded'
      )

      expect(last_response.status).to eq(302)

      location = last_response.headers['Location']

      session_id = location.split('/').last
      session = repo.find(session_id)

      expect(session).to be_present

      options.each do |key, value|
        option = session.suite_options.find { |suite_option| suite_option.id == key }
        expect(option.value).to eq(value)
      end
    end

    it 'applies supplied preset' do
      preset_id = 'demo_preset'

      post(
        router.path(:session_form_post, test_suite_id: 'demo'),
        URI.encode_www_form(preset_id:),
        'Content-Type' => 'application/x-www-form-urlencoded'
      )

      expect(last_response.status).to eq(302)

      location = last_response.headers['Location']

      session_id = location.split('/').last
      session = repo.find(session_id)

      expect(session).to be_present

      expect(session_data_repo.load(test_session_id: session.id, name: 'patient_id')).to eq('85')
      expect(session_data_repo.load(test_session_id: session.id, name: 'bearer_token')).to eq('SAMPLE_TOKEN')
    end

    it 'applies supplied inputs' do
      inputs = [
        { name: 'v1_input', value: '1', type: 'text' },
        { name: 'v2_input', value: '2', type: 'text' },
        { name: 'all_versions_input', value: '3', type: 'text' }
      ]

      form_data = inputs.flat_map do |input|
        input.map { |k, v| ["inputs[][#{k}]", v] }
      end

      post(
        router.path(:session_form_post, test_suite_id:),
        URI.encode_www_form(form_data),
        'Content-Type' => 'application/x-www-form-urlencoded'
      )

      expect(last_response.status).to eq(302)

      location = last_response.headers['Location']
      session_id = location.split('/').last

      inputs.each do |input|
        expect(
          session_data_repo.load(test_session_id: session_id, name: input[:name])
        ).to eq(input[:value])
      end
    end

    it 'creates the session even when required inputs are missing' do
      inputs = [
        { name: 'v1_input', value: '1', type: 'text' },
        { name: 'v2_input', value: '2', type: 'text' }
      ]
      form_data = inputs.flat_map do |input|
        input.map { |k, v| ["inputs[][#{k}]", v] }
      end

      post(
        router.path(:session_form_post, test_suite_id:),
        URI.encode_www_form(form_data),
        'Content-Type' => 'application/x-www-form-urlencoded'
      )

      expect(last_response.status).to eq(302)

      location = last_response.headers['Location']
      session_id = location.split('/').last

      inputs.each do |input|
        expect(
          session_data_repo.load(test_session_id: session_id, name: input[:name])
        ).to eq(input[:value])
      end
    end
  end

  context 'with invalid params' do
    it 'returns a 404 when the suite can not be found' do
      post router.path(:session_form_post, test_suite_id: 'bad_suite_id')

      expect(last_response.status).to eq(404)
    end

    it 'returns a 422 when the preset can not be found' do
      preset_id = 'bad_preset_id'

      post(
        router.path(:session_form_post, test_suite_id: 'demo'),
        URI.encode_www_form(preset_id:),
        'Content-Type' => 'application/x-www-form-urlencoded'
      )

      expect(last_response.status).to eq(422)
    end
  end
end
