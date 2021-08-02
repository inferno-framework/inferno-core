require_relative '../../dev_suites/smart/standalone_launch_group'
require_relative '../request_helper'

RSpec.describe SMART::StandaloneLaunchGroup do
  include Rack::Test::Methods
  include RequestHelpers

  let(:suite) { Inferno::Repositories::TestSuites.new.find('smart') }
  let(:group) { Inferno::Repositories::TestGroups.new.find('smart_standalone_launch') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:requests_repo) { Inferno::Repositories::Requests.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'smart') }
  let(:url) { 'http://example.com/fhir' }

  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(test_session_id: test_session.id, name: name, value: value)
    end
    Inferno::TestRunner.new(test_session: test_session, test_run: test_run).run(runnable)
  end

  def create_redirect_request(url)
    repo_create(
      :request,
      direction: 'incoming',
      name: 'standalone_redirect',
      url: url,
      test_session_id: test_session.id
    )
  end

  def create_token_request(body: nil, status: 200, headers: nil)
    headers ||= [
      {
        type: 'response',
        name: 'Cache-Control',
        value: 'no-store'
      },
      {
        type: 'response',
        name: 'Pragma',
        value: 'no-cache'
      }
    ]
    repo_create(
      :request,
      direction: 'outgoing',
      name: 'standalone_token',
      url: 'http://example.com/token',
      test_session_id: test_session.id,
      response_body: body.is_a?(Hash) ? body.to_json : body,
      status: status,
      headers: headers
    )
  end

  describe 'browser redirect test' do
    let(:runnable) { group.tests.first }
    let(:inputs) do
      {
        client_id: 'CLIENT_ID',
        redirect_uri: 'http://example.com/redirect',
        requested_scopes: 'REQUESTED_SCOPES',
        url: url,
        smart_authorization_url: 'http://example.com/auth'
      }
    end

    it 'waits and then passes when it receives a request with the correct state' do
      result = run(runnable, inputs)
      expect(result.result).to eq('wait')

      state = session_data_repo.load(test_session_id: test_session.id, name: 'state')
      get "/custom/smart/redirect?state=#{state}"

      result = results_repo.find(result.id)
      expect(result.result).to eq('pass')
    end

    it 'continues to wait when it receives a request with the incorrect state' do
      result = run(runnable, inputs)
      expect(result.result).to eq('wait')

      state = SecureRandom.uuid
      get "/custom/smart/redirect?state=#{state}"

      result = results_repo.find(result.id)
      expect(result.result).to eq('wait')
    end

    it 'fails if the authorization url is invalid' do
      result = run(runnable, smart_authorization_url: 'xyz')
      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/is not a valid URI/)
    end

    it "persists the incoming 'standalone_redirect' request" do
      run(runnable, inputs)
      state = session_data_repo.load(test_session_id: test_session.id, name: 'state')
      url = "/custom/smart/redirect?state=#{state}"
      get url

      request = requests_repo.find_named_request(test_session.id, 'standalone_redirect')
      expect(request.url).to end_with(url)
    end

    it "persists the 'state' output" do
      result = run(runnable, inputs)
      expect(result.result).to eq('wait')

      state = result.result_message.match(/`(.*)`/)[1]
      persisted_state = session_data_repo.load(test_session_id: test_session.id, name: 'state')

      expect(persisted_state).to eq(state)
    end
  end

  describe 'code received test' do
    let(:runnable) { group.tests[1] }

    it 'passes if it receives a code with no error' do
      create_redirect_request('http://example.com/redirect?code=CODE')
      result = run(runnable, code: 'CODE')

      expect(result.result).to eq('pass')
    end

    it 'fails if it receives an error' do
      create_redirect_request('http://example.com/redirect?code=CODE&error=invalid_request')
      result = run(runnable, code: 'CODE')

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/Error returned from authorization server/)
      expect(result.result_message).to include('invalid_request')
    end

    it 'includes the error description and uri in the failure message if present' do
      create_redirect_request(
        'http://example.com/redirect?code=CODE&error=invalid_request&error_description=DESCRIPTION&error_uri=URI'
      )
      result = run(runnable, code: 'CODE')

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/Error returned from authorization server/)
      expect(result.result_message).to include('DESCRIPTION')
      expect(result.result_message).to include('URI')
    end
  end

  describe 'token exchange test' do
    let(:runnable) { group.tests[2] }
    let(:token_url) { 'http://example.com/token' }
    let(:public_inputs) do
      {
        code: 'CODE',
        smart_token_url: token_url,
        client_id: 'CLIENT_ID'
      }
    end
    let(:confidential_inputs) { public_inputs.merge(client_secret: 'CLIENT_SECRET') }

    context 'with a confidential client' do
      it 'passes if the token response has a 200 status', pending: true do
        create_redirect_request('http://example.com/redirect?code=CODE')
        stub_request(:post, token_url)
          .with(
            body: { grant_type: 'authorization_code', code: 'CODE', redirect_uri: '' },
            headers: { 'Authorization' => "Basic #{Base64.strict_encode64('CLIENT_ID:CLIENT_SECRET')}" }
          )
          .to_return(status: 200)

        result = run(runnable, confidential_inputs)

        expect(result.result).to eq('pass')
      end
    end

    context 'with a public client' do
      it 'passes if the token response has a 200 status' do
        create_redirect_request('http://example.com/redirect?code=CODE')
        stub_request(:post, token_url)
          .with(body: { grant_type: 'authorization_code', code: 'CODE', client_id: 'CLIENT_ID', redirect_uri: '' })
          .to_return(status: 200)

        result = run(runnable, public_inputs)

        expect(result.result).to eq('pass')
      end
    end

    it 'fails if a non-200 response is received' do
      create_redirect_request('http://example.com/redirect?code=CODE')
      stub_request(:post, token_url)
        .with(body: { grant_type: 'authorization_code', code: 'CODE', client_id: 'CLIENT_ID', redirect_uri: '' })
        .to_return(status: 201)

      result = run(runnable, public_inputs)

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/Bad response status/)
    end

    it 'skips if the auth request had an error' do
      create_redirect_request('http://example.com/redirect?code=CODE&error=invalid_request')

      result = run(runnable, public_inputs)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('Error during authorization request')
    end
  end

  describe 'token response body test' do
    let(:runnable) { group.tests[3] }

    it 'passes if the body contains the required fields' do
      create_token_request(body: { access_token: 'ACCESS_TOKEN', token_type: 'bearer' })

      result = run(runnable)

      expect(result.result).to eq('pass')
    end

    it 'skips if the token request was not successful' do
      create_token_request(body: { access_token: 'ACCESS_TOKEN', token_type: 'bearer' }, status: 500)

      result = run(runnable)

      expect(result.result).to eq('skip')
      expect(result.result_message).to match(/was unsuccessful/)
    end

    it 'fails if the body is not valid json' do
      create_token_request(body: '[[')

      result = run(runnable)

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/Invalid JSON/)
    end

    it 'fails if the body does not contain an access token' do
      create_token_request(body: { token_type: 'bearer' })

      result = run(runnable)

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/did not contain an access token/)
    end

    it 'fails if the body does not contain a token type' do
      create_token_request(body: { access_token: 'ACCESS_TOKEN' })

      result = run(runnable)

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/`token_type` field must have/)
    end

    it 'persists outputs' do
      inputs = {
        access_token: 'ACCESS_TOKEN',
        id_token: 'ID_TOKEN',
        refresh_token: 'REFRESH_TOKEN',
        expires_in: 'EXPIRES_IN',
        patient: 'PATIENT',
        encounter: 'ENCOUNTER',
        scope: 'SCOPE',
        token_type: 'BEARER',
        intent: 'INTENT'
      }
      expected_outputs = {
        standalone_id_token: inputs[:id_token],
        standalone_refresh_token: inputs[:refresh_token],
        standalone_access_token: inputs[:access_token],
        standalone_expires_in: inputs[:expires_in],
        standalone_patient_id: inputs[:patient],
        standalone_encounter_id: inputs[:encounter],
        standalone_received_scopes: inputs[:scope],
        standalone_intent: inputs[:intent]
      }
      create_token_request(body: inputs)

      result = run(runnable)

      expect(result.result).to eq('pass')

      expected_outputs.each do |name, value|
        persisted_data = session_data_repo.load(test_session_id: test_session.id, name: name)

        expect(persisted_data).to eq(value)
      end
    end
  end

  describe 'token response headers test' do
    let(:runnable) { group.tests[4] }

    it 'passes if the response contains headers with the required values' do
      create_token_request

      result = run(runnable)

      expect(result.result).to eq('pass')
    end

    it 'skips if the token request was not successful' do
      create_token_request(status: 500)

      result = run(runnable)

      expect(result.result).to eq('skip')
      expect(result.result_message).to match(/was unsuccessful/)
    end

    it 'fails if the required headers are not present' do
      create_token_request(headers: [])

      result = run(runnable)

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/Token response must have/)
    end

    it 'fails if the Cache-Control header does not contain no-store' do
      create_token_request(
        headers: [
          {
            type: 'response',
            name: 'Cache-Control',
            value: 'abc'
          },
          {
            type: 'response',
            name: 'Pragma',
            value: 'no-cache'
          }
        ]
      )

      result = run(runnable)

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/`Cache-Control`/)
    end

    it 'fails if the Pragma header does not contain no-cache' do
      create_token_request(
        headers: [
          {
            type: 'response',
            name: 'Cache-Control',
            value: 'no-store'
          },
          {
            type: 'response',
            name: 'Pragma',
            value: 'abc'
          }
        ]
      )

      result = run(runnable)

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/`Pragma`/)
    end
  end
end
