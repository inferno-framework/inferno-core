require_relative '../../dev_suites/dev_smart/token_refresh_test'
require_relative '../request_helper'

RSpec.describe SMART::TokenRefreshTest do
  include Rack::Test::Methods
  include RequestHelpers

  let(:test) { Inferno::Repositories::Tests.new.find('smart_token_refresh') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:requests_repo) { Inferno::Repositories::Requests.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'smart') }
  let(:token_url) { 'http://example.com/fhir/token' }
  let(:refresh_token) { 'REFRESH_TOKEN' }
  let(:client_id) { 'CLIENT_ID' }
  let(:client_secret) { 'CLIENT_SECRET' }
  let(:received_scopes) { 'openid profile launch offline_access patient/*.*' }
  let(:valid_response) do
    {
      access_token: 'ACCESS_TOKEN',
      token_type: 'Bearer',
      expires_in: 3600,
      scope: received_scopes,
      refresh_token: 'REFRESH_TOKEN2'
    }
  end

  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(test_session_id: test_session.id, name: name, value: value)
    end
    Inferno::TestRunner.new(test_session: test_session, test_run: test_run).run(runnable)
  end

  it 'skips if no refresh_token is available' do
    result = run(test, refresh_token: nil)

    expect(result.result).to eq('skip')
  end

  context 'with a public client' do
    it 'passes when the refresh succeeds' do
      stub_request(:post, token_url)
        .to_return(
          status: 200,
          headers: {
            'Content-Type': 'application/json'
          },
          body: valid_response.to_json
        )

      result = run(
        test,
        well_known_token_url: token_url,
        refresh_token: refresh_token,
        client_id: client_id,
        received_scopes: received_scopes
      )

      expect(result.result).to eq('pass')
    end
  end

  context 'with a confidential client' do
    it 'passes when the refresh succeeds' do
      credentials = Base64.strict_encode64("#{client_id}:#{client_secret}")
      stub_request(:post, token_url)
        .with(
          headers: {
            Authorization: "Basic #{credentials}"
          }
        )
        .to_return(
          status: 200,
          headers: {
            'Content-Type': 'application/json'
          },
          body: valid_response.to_json
        )

      result = run(
        test,
        well_known_token_url: token_url,
        refresh_token: refresh_token,
        client_id: client_id,
        client_secret: client_secret,
        received_scopes: received_scopes
      )

      expect(result.result).to eq('pass')
    end
  end

  it 'fails if a non-200/201 response is received' do
    stub_request(:post, token_url)
      .to_return(
        status: 202,
        headers: {
          'Content-Type': 'application/json'
        },
        body: valid_response.to_json
      )

    result = run(
      test,
      well_known_token_url: token_url,
      refresh_token: refresh_token,
      client_id: client_id,
      received_scopes: received_scopes
    )

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/202/)
  end

  it 'fails if a non-json response is received' do
    stub_request(:post, token_url)
      .to_return(
        status: 200,
        headers: {
          'Content-Type': 'application/json'
        },
        body: '[['
      )

    result = run(
      test,
      well_known_token_url: token_url,
      refresh_token: refresh_token,
      client_id: client_id,
      received_scopes: received_scopes
    )

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/Invalid JSON/)
  end

  it 'persists request' do
    stub_request(:post, token_url)
      .to_return(
        status: 200,
        headers: {
          'Content-Type': 'application/json'
        },
        body: valid_response.to_json
      )

    result = run(
      test,
      well_known_token_url: token_url,
      refresh_token: refresh_token,
      client_id: client_id,
      received_scopes: received_scopes
    )

    expect(result.result).to eq('pass')

    request = requests_repo.find_named_request(test_session.id, :token_refresh)
    expect(request).to be_present
  end
end
