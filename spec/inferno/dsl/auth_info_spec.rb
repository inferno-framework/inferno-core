RSpec.describe Inferno::DSL::AuthInfo do
  let(:auth_url) { 'https://inferno-qa.healthit.gov/reference-server/oauth/authorization' }
  let(:token_url) { 'https://inferno-qa.healthit.gov/reference-server/oauth/token' }
  let(:requested_scopes) { 'launch/patient openid fhirUser patient/*.*' }
  let(:encryption_algorithm) { 'ES384' }
  let(:kid) { '4b49a739d1eb115b3225f4cf9beb6d1b' }
  let(:jwks) do
    {
      keys:
       [
         {
           kty: 'EC',
           crv: 'P-384',
           x: 'JQKTsV6PT5Szf4QtDA1qrs0EJ1pbimQmM2SKvzOlIAqlph3h1OHmZ2i7MXahIF2C',
           y: 'bRWWQRJBgDa6CTgwofYrHjVGcO-A7WNEnu4oJA5OUJPPPpczgx1g2NsfinK-D2Rw',
           use: 'sig',
           key_ops: [
             'verify'
           ],
           ext: true,
           kid: '4b49a739d1eb115b3225f4cf9beb6d1b',
           alg: 'ES384'
         },
         {
           kty: 'EC',
           crv: 'P-384',
           d: 'kDkn55p7gryKk2tj6z2ij7ExUnhi0ngxXosvqa73y7epwgthFqaJwApmiXXU2yhK',
           x: 'JQKTsV6PT5Szf4QtDA1qrs0EJ1pbimQmM2SKvzOlIAqlph3h1OHmZ2i7MXahIF2C',
           y: 'bRWWQRJBgDa6CTgwofYrHjVGcO-A7WNEnu4oJA5OUJPPPpczgx1g2NsfinK-D2Rw',
           key_ops: [
             'sign'
           ],
           ext: true,
           kid: '4b49a739d1eb115b3225f4cf9beb6d1b',
           alg: 'ES384'
         }
       ]
    }.to_json
  end
  let(:issue_time) { Time.now.iso8601 }
  let(:token_info) do
    {
      access_token: 'SAMPLE_TOKEN',
      refresh_token: 'SAMPLE_REFRESH_TOKEN',
      expires_in: '3600',
      issue_time:
    }
  end
  let(:full_params) do
    {
      access_token: 'ACCESS_TOKEN',
      refresh_token: 'REFRESH_TOKEN',
      issue_time: Time.now.iso8601,
      expires_in: 3600,
      token_url: 'http://example.com/token',
      client_id: 'CLIENT_ID',
      client_secret: 'CLIENT_SECRET',
      auth_url: 'http://example.com/authorization',
      requested_scopes: 'launch/patient openid fhirUser patient/*.*',
      pkce_support: 'enabled',
      pkce_code_challenge_method: 'S256',
      auth_request_method: 'POST',
      use_discovery: 'false',
      name: 'NAME'
    }
  end
  let(:public_access_default) do
    {
      auth_type: 'public',
      client_id: 'SAMPLE_PUBLIC_CLIENT_ID',
      requested_scopes:,
      pkce_support: 'enabled',
      pkce_code_challenge_method: 'S256',
      auth_request_method: 'GET'
    }.merge(token_info)
  end
  let(:symmetric_confidential_access_default) do
    {
      auth_type: 'symmetric',
      token_url:,
      client_id: 'SAMPLE_CONFIDENTIAL_CLIENT_ID',
      client_secret: 'SAMPLE_CONFIDENTIAL_CLIENT_SECRET',
      auth_url:,
      requested_scopes:,
      pkce_support: 'enabled',
      pkce_code_challenge_method: 'S256',
      auth_request_method: 'POST',
      use_discovery: 'false'
    }.merge(token_info)
  end
  let(:asymmetric_confidential_access_default) do
    {
      auth_type: 'asymmetric',
      client_id: 'SAMPLE_CONFIDENTIAL_CLIENT_ID',
      requested_scopes:,
      pkce_support: 'disabled',
      auth_request_method: 'POST',
      encryption_algorithm:,
      jwks:,
      kid:
    }.merge(token_info)
  end
  let(:backend_services_access_default) do
    {
      auth_type: 'backend_services',
      client_id: 'SAMPLE_CONFIDENTIAL_CLIENT_ID',
      requested_scopes:,
      encryption_algorithm:,
      jwks:,
      kid:
    }.merge(token_info)
  end
  let(:auth_info) { described_class.new(full_params) }
  let(:public_auth_info) { described_class.new(public_access_default) }
  let(:symmetric_auth_info) { described_class.new(symmetric_confidential_access_default) }
  let(:asymmetric_auth_info) { described_class.new(asymmetric_confidential_access_default) }
  let(:backend_services_auth_info) { described_class.new(backend_services_access_default) }
  let(:client) { FHIR::Client.new('http://example.com') }

  describe '.new' do
    it 'raises an error if an invalid key is provided' do
      expect { described_class.new(bad_key: 'abc') }.to(
        raise_error(
          Inferno::Exceptions::UnknownAttributeException, /bad_key/
        )
      )
    end
  end

  describe '#add_to_client' do
    it 'sets the auth info on the client' do
      auth_info.add_to_client(client)

      expect(client.auth_info).to eq(auth_info)
    end

    context 'when a bearer token is present' do
      it 'sets the bearer token on the client' do
        auth_info.add_to_client(client)

        expect(client.security_headers['Authorization']).to eq("Bearer #{auth_info.access_token}")
      end
    end

    context 'when no bearer token is present' do
      it 'does not set the bearer token on the client' do
        client.set_bearer_token('BEARER_TOKEN')
        auth_info.access_token = nil
        auth_info.add_to_client(client)

        expect(client.security_headers['Authorization']).to eq('Bearer BEARER_TOKEN')
      end
    end
  end

  describe '#to_hash' do
    it 'generates a hash containing all present attributes' do
      hash = { access_token: 'TOKEN', client_id: 'CLIENT_ID' }

      expect(described_class.new(hash).to_hash).to include(hash)
    end
  end

  describe '#to_s' do
    it 'generates a JSON string containing all present attributes' do
      hash = { access_token: 'TOKEN', client_id: 'CLIENT_ID' }

      expect(JSON.parse(described_class.new(hash).to_s)).to include(hash.stringify_keys)
    end
  end

  describe '#need_to_refresh?' do
    it 'returns false if there is no access token' do
      auth_info.access_token = nil
      expect(auth_info.need_to_refresh?).to be(false)
    end

    it 'returns true if there is no expires_in' do
      auth_info.expires_in = nil
      expect(auth_info.need_to_refresh?).to be(true)
    end

    it 'returns true if the token has will expire in under a minute' do
      auth_info.expires_in = 59
      expect(auth_info.need_to_refresh?).to be(true)
    end

    it 'returns true if the token has expired' do
      auth_info.issue_time = 2.hours.ago
      expect(auth_info.need_to_refresh?).to be(true)
    end

    it 'returns false if the token is valid for over a minute' do
      auth_info.expires_in = 61
      expect(auth_info.need_to_refresh?).to be(false)
    end

    context 'when public, symmetric, or asymmetric auth' do
      it 'returns false if there is no refresh token' do
        public_auth_info.refresh_token = nil
        symmetric_auth_info.refresh_token = nil
        asymmetric_auth_info.refresh_token = nil

        expect(public_auth_info.need_to_refresh?).to be(false)
        expect(symmetric_auth_info.need_to_refresh?).to be(false)
        expect(asymmetric_auth_info.need_to_refresh?).to be(false)
      end
    end

    context 'when backend services auth' do
      it 'returns true if no refresh token and access token expired' do
        backend_services_auth_info.refresh_token = nil
        backend_services_auth_info.issue_time = 2.hours.ago
        expect(backend_services_auth_info.need_to_refresh?).to be(true)
      end
    end
  end
end
