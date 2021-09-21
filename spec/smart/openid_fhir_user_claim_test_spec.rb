require_relative '../../dev_suites/dev_smart/openid_fhir_user_claim_test'

RSpec.describe SMART::OpenIDFHIRUserClaimTest do
  let(:test) { Inferno::Repositories::Tests.new.find('smart_openid_fhir_user_claim') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'smart') }
  let(:url) { 'http://example.com/fhir' }
  let(:scopes) { 'fhirUser' }
  let(:payload) do
    {
      fhirUser: "#{url}/Patient/123"
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

  it 'skips if no token payload is available' do
    result = run(test, id_token_payload_json: nil)

    expect(result.result).to eq('skip')
  end

  it 'skips if no fhirUser scope was requested' do
    result = run(test, id_token_payload_json: nil, requested_scopes: 'launch')

    expect(result.result).to eq('skip')
  end

  it 'passes when the fhirUser claim is present' do
    result = run(test, id_token_payload_json: payload.to_json, requested_scopes: scopes)

    expect(result.result).to eq('pass')
  end

  it 'fails if the fhirUser claim is blank' do
    result = run(test, id_token_payload_json: { fhirUser: '' }.to_json, requested_scopes: scopes)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/does not contain/)
  end

  it 'fails if the fhirUser claim does not refer to a valid resource type' do
    result = run(test, id_token_payload_json: { fhirUser: "#{url}/Observation/123" }.to_json, requested_scopes: scopes)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/resource type/)
  end

  it 'persists outputs' do
    result = run(test, id_token_payload_json: payload.to_json, requested_scopes: scopes)

    expect(result.result).to eq('pass')

    persisted_user = session_data_repo.load(test_session_id: test_session.id, name: :id_token_fhir_user)
    expect(persisted_user).to eq(payload[:fhirUser])
  end
end
