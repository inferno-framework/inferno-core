require_relative '../../dev_suites/dev_smart/openid_required_configuration_fields_test'

RSpec.describe SMART::OpenIDRequiredConfigurationFieldsTest do
  let(:test) { Inferno::Repositories::Tests.new.find('smart_openid_required_configuration_fields') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'smart') }
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
      issuer: 'https://www.example.com/',
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

  it 'skips if no configuration is available' do
    result = run(test, openid_configuration_json: nil)

    expect(result.result).to eq('skip')
  end

  it 'passes when the configuration contains all required fields' do
    result = run(test, openid_configuration_json: config.to_json)

    expect(result.result).to eq('pass')
  end

  it 'persists outputs' do
    result = run(test, openid_configuration_json: config.to_json)

    expect(result.result).to eq('pass')

    persisted_uri = session_data_repo.load(test_session_id: test_session.id, name: :openid_jwks_uri)
    expect(persisted_uri).to eq(config[:jwks_uri])
  end

  it 'fails if a required field is missing' do
    test::REQUIRED_FIELDS.each do |field|
      bad_config = config.reject { |key, _| key == field.to_sym }

      result = run(test, openid_configuration_json: bad_config.to_json)

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/`#{field}`/)
    end
  end

  it 'fails if RS256 is not supported' do
    config[:id_token_signing_alg_values_supported].delete 'RS256'
    result = run(test, openid_configuration_json: config.to_json)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/RSA SHA-256/)
  end
end
