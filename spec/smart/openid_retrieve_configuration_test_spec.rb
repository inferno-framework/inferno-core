require_relative '../../dev_suites/dev_smart/openid_retrieve_configuration_test'
require_relative '../request_helper'

RSpec.describe SMART::OpenIDRetrieveConfigurationTest do
  include Rack::Test::Methods
  include RequestHelpers

  let(:test) { Inferno::Repositories::Tests.new.find('smart_openid_retrieve_configuration') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:requests_repo) { Inferno::Repositories::Requests.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'smart') }
  let(:url) { 'http://example.com/fhir' }
  let(:client_id) { 'CLIENT_ID' }
  let(:payload) do
    {
      iss: url,
      exp: 1.hour.from_now.to_i,
      nbf: Time.now.to_i,
      iat: Time.now.to_i,
      aud: client_id,
      sub: SecureRandom.uuid,
      fhirUser: "#{url}/Patient/123"
    }
  end
  let(:config) do
    {
      registration_endpoint: 'https://www.example.com/register',
      token_endpoint: 'https://www.example.com/token',
      token_endpoint_auth_methods_supported: ['client_secret_post', 'client_secret_basic', 'none'],
      jwks_uri: 'https://www.example.com/jwk',
      id_token_signing_alg_values_supported: ['HS256', 'HS384', 'HS512', 'RS256', 'RS384', 'RS512', 'none'],
      authorization_endpoint: 'https://www.example.com/authorize',
      introspection_endpoint: 'https://www.example.com/introspect',
      response_types_supported: ['code'],
      grant_types_supported: ['authorization_code'],
      scopes_supported: ['launch', 'openid', 'patient/*.*', 'profile'],
      userinfo_endpoint: 'https://www.example.com/userinfo',
      issuer: url,
      subject_types_supported: 'public'
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

  it 'skips if no id token is available' do
    result = run(test, id_token_payload_json: nil)

    expect(result.result).to eq('skip')
  end

  it 'passes when the configuration can be retrieved' do
    stub_request(:get, "#{url}/.well-known/openid-configuration")
      .to_return(
        status: 200,
        headers: {
          'Content-Type': 'application/json'
        },
        body: config.to_json
      )
    result = run(test, id_token_payload_json: payload.to_json)

    expect(result.result).to eq('pass')
  end

  it 'persists outputs and request' do
    stub_request(:get, "#{url}/.well-known/openid-configuration")
      .to_return(
        status: 200,
        headers: {
          'Content-Type': 'application/json'
        },
        body: config.to_json
      )
    result = run(test, id_token_payload_json: payload.to_json)

    expect(result.result).to eq('pass')

    persisted_config = session_data_repo.load(test_session_id: test_session.id, name: :openid_configuration_json)
    expect(persisted_config).to be_present
    expect(JSON.parse(persisted_config).deep_symbolize_keys).to eq(config)

    persisted_issuer = session_data_repo.load(test_session_id: test_session.id, name: :openid_issuer)
    expect(persisted_issuer).to eq(payload[:iss])

    request = requests_repo.find_named_request(test_session.id, :openid_configuration)
    expect(request).to be_present
  end

  it 'fails if a non-200 response is received' do
    stub_request(:get, "#{url}/.well-known/openid-configuration")
      .to_return(status: 201)
    result = run(test, id_token_payload_json: payload.to_json)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/200/)
  end

  it 'fails if the content-type is not present' do
    stub_request(:get, "#{url}/.well-known/openid-configuration")
      .to_return(
        status: 200
      )
    result = run(test, id_token_payload_json: payload.to_json)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/Content-Type/)
  end

  it 'fails if the content-type is not application/json' do
    stub_request(:get, "#{url}/.well-known/openid-configuration")
      .to_return(
        status: 200,
        headers: { 'Content-Type': 'application/xml' }
      )
    result = run(test, id_token_payload_json: payload.to_json)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(%r{application/json})
  end

  it 'fails if the response body is not valid json' do
    stub_request(:get, "#{url}/.well-known/openid-configuration")
      .to_return(
        status: 200,
        headers: {
          'Content-Type': 'application/json'
        },
        body: 'xyz'
      )
    result = run(test, id_token_payload_json: payload.to_json)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/Invalid JSON/)
  end
end
