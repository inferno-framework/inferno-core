require_relative '../../dev_suites/smart/discovery_group'


RSpec.describe SMART::DiscoveryGroup do
  let(:suite) { Inferno::Repositories::TestSuites.new.find('smart') }
  let(:group) { Inferno::Repositories::TestGroups.new.find('smart_discovery') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'smart') }
  let(:url) { 'http://example.com/fhir' }
  let(:well_known_url) { 'http://example.com/fhir/.well-known/smart-configuration' }
  let(:well_known_config) do
    {
      "authorization_endpoint" => "https://example.com/fhir/auth/authorize",
      "token_endpoint" => "https://example.com/fhir/auth/token",
      "token_endpoint_auth_methods_supported" => ["client_secret_basic"],
      "registration_endpoint" => "https://example.com/fhir/auth/register",
      "scopes_supported" =>
        ["openid", "profile", "launch", "launch/patient", "patient/*.*", "user/*.*", "offline_access"],
      "response_types_supported" => ["code", "code id_token", "id_token", "refresh_token"],
      "management_endpoint" => "https://example.com/fhir/user/manage",
      "introspection_endpoint" => "https://example.com/fhir/user/introspect",
      "revocation_endpoint" => "https://example.com/fhir/user/revoke",
      "capabilities" =>
        ["launch-ehr", "client-public", "client-confidential-symmetric", "context-ehr-patient", "sso-openid-connect"]
    }
  end

  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(test_session_id: test_session.id, name: name, value: value)
    end
    Inferno::TestRunner.new(test_session: test_session, test_run: test_run).run(runnable)
    Inferno::Repositories::TestRuns.new.results_for_test_run(test_run.id)
  end

  describe 'well-known endpoint test' do
    let(:runnable) { group.tests.first }

    it 'passes when a valid well-known configuration is received' do
      stub_request(:get, well_known_url)
        .to_return(status: 200, body: well_known_config.to_json, headers: { 'Content-Type' => 'application/json' })
      result = run(runnable, url: url).first

      expect(result.result).to eq('pass')
    end

    it 'fails when a non-200 response is received' do
      stub_request(:get, well_known_url)
        .to_return(status: 201, body: well_known_config.to_json, headers: { 'Content-Type' => 'application/json' })
      result = run(runnable, url: url).first

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/Bad response status:/)
    end

    it 'fails when a Content-Type header is not received' do
      stub_request(:get, well_known_url)
        .to_return(status: 200, body: well_known_config.to_json)
      result = run(runnable, url: url).first

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/No.*header received/)
    end

    it 'fails when an incorrect Content-Type header is received' do
      stub_request(:get, well_known_url)
        .to_return(status: 200, body: well_known_config.to_json, headers: { 'Content-Type' => 'application/xml' })
      result = run(runnable, url: url).first

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(%r(`Content-Type` must be `application/json`))
    end

    it 'fails when the body is invalid json' do
      stub_request(:get, well_known_url)
        .to_return(status: 200, body: '[[', headers: { 'Content-Type' => 'application/json' })
      result = run(runnable, url: url).first

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/Invalid JSON/)
    end

    it 'persists outputs' do
      stub_request(:get, well_known_url)
        .to_return(status: 200, body: well_known_config.to_json, headers: { 'Content-Type' => 'application/json' })
      run(runnable, url: url).first
      ['authorization', 'introspection', 'management', 'registration', 'revocation', 'token'].each do |type|
        value = session_data_repo.load(test_session_id: test_session.id, name: "well_known_#{type}_url")
        expect(value).to be_present
        expect(value).to eq(well_known_config["#{type}_endpoint"])
      end
    end
  end
end
