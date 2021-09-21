require_relative '../../dev_suites/dev_smart/openid_decode_id_token_test'

RSpec.describe SMART::OpenIDDecodeIDTokenTest do
  let(:test) { Inferno::Repositories::Tests.new.find('smart_openid_decode_id_token') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
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
  let(:key_pair) { OpenSSL::PKey::RSA.new(2048) }
  let(:jwk) { JWT::JWK.new(key_pair) }
  let(:id_token) { JWT.encode(payload, key_pair, 'RS256', kid: jwk.kid) }

  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(test_session_id: test_session.id, name: name, value: value)
    end
    Inferno::TestRunner.new(test_session: test_session, test_run: test_run).run(runnable)
  end

  it 'skips if no id token is available' do
    result = run(test, id_token: '')

    expect(result.result).to eq('skip')
  end

  it 'passes when the token can be decoded' do
    result = run(test, id_token: id_token)

    expect(result.result).to eq('pass')
  end

  it 'persists outputs' do
    result = run(test, id_token: id_token)

    expect(result.result).to eq('pass')

    persisted_payload = session_data_repo.load(test_session_id: test_session.id, name: :id_token_payload_json)
    expect(persisted_payload).to be_present

    persisted_header = session_data_repo.load(test_session_id: test_session.id, name: :id_token_header_json)
    expect(persisted_header).to be_present

    expected_header = {
      alg: 'RS256',
      kid: jwk.kid
    }

    expect(JSON.parse(persisted_payload).deep_symbolize_keys).to eq(payload)
    expect(JSON.parse(persisted_header).deep_symbolize_keys).to eq(expected_header)
  end
end
