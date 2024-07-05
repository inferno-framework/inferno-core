RSpec.describe Inferno::DSL::AuthInfo do
  let(:auth_url) { 'http://example.com/authorization' }
  let(:token_url) { 'http://example.com/token' }
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
      token_url:,
      client_id: 'CLIENT_ID',
      client_secret: 'CLIENT_SECRET',
      auth_url:,
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
      token_url:,
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
      token_url:,
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
      token_url:,
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
        [public_auth_info, symmetric_auth_info, asymmetric_auth_info].each do |credentials|
          credentials.refresh_token = nil
          expect(credentials.need_to_refresh?).to be(false)
        end
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

  describe '#able_to_refresh?' do
    context 'when public, symmetric, or asymmetric auth' do
      it 'returns true if a refresh token and token url are present' do
        [public_auth_info, symmetric_auth_info, asymmetric_auth_info].each do |credentials|
          expect(credentials.able_to_refresh?).to be(true)
        end
      end

      it 'returns false if the refresh token or token url are missing' do
        [:refresh_token, :token_url].each do |field|
          [public_access_default, symmetric_confidential_access_default,
           asymmetric_confidential_access_default].each do |params|
            expect(described_class.new(params.merge("#{field}": nil)).able_to_refresh?).to be(false)
          end
        end
      end
    end

    context 'when backend services auth' do
      it 'returns true if token url is present' do
        expect(backend_services_auth_info.able_to_refresh?).to be(true)
      end

      it 'returns false if the token url is missing' do
        backend_services_auth_info.token_url = nil
        expect(backend_services_auth_info.able_to_refresh?).to be(false)
      end
    end
  end

  describe '#oauth2_refresh_params' do
    context 'when public auth' do
      it 'returns a hash with grant_type, refresh_token, and client_id params' do
        params = public_auth_info.oauth2_refresh_params
        expect(params).to include('grant_type', 'refresh_token', 'client_id')
        expect(params['grant_type']).to eq('refresh_token')
        expect(params['refresh_token']).to eq(public_auth_info.refresh_token)
        expect(params['client_id']).to eq(public_auth_info.client_id)
      end
    end

    context 'when symmetric auth' do
      it 'returns a hash with grant_type and refresh_token params' do
        params = symmetric_auth_info.oauth2_refresh_params
        expect(params).to include('grant_type', 'refresh_token')
        expect(params['grant_type']).to eq('refresh_token')
        expect(params['refresh_token']).to eq(symmetric_auth_info.refresh_token)
      end
    end

    context 'when asymmetric auth' do
      it 'returns a hash with grant_type, refresh_token, client_assertion_type, and client_assertion params' do
        params = asymmetric_auth_info.oauth2_refresh_params
        expect(params).to include('grant_type', 'refresh_token', 'client_assertion_type', 'client_assertion')
        expect(params['grant_type']).to eq('refresh_token')
        expect(params['refresh_token']).to eq(asymmetric_auth_info.refresh_token)
        expect(params['client_assertion_type']).to eq('urn:ietf:params:oauth:client-assertion-type:jwt-bearer')
      end
    end

    context 'when backend services auth' do
      it 'returns a hash with grant_type, scope, client_assertion_type, and client_assertion params' do
        params = backend_services_auth_info.oauth2_refresh_params
        expect(params).to include('grant_type', 'scope', 'client_assertion_type', 'client_assertion')
        expect(params['grant_type']).to eq('client_credentials')
        expect(params['scope']).to eq(backend_services_auth_info.requested_scopes)
        expect(params['client_assertion_type']).to eq('urn:ietf:params:oauth:client-assertion-type:jwt-bearer')
      end
    end
  end

  describe '#oauth2_refresh_headers' do
    context 'when symmetric auth' do
      it 'returns a hash with Content-Type and Authorization headers' do
        expect(symmetric_auth_info.oauth2_refresh_headers).to include('Authorization', 'Content-Type')
      end
    end

    context 'when public, asymmetric, or backend services auth' do
      it 'returns a hash with a Content-Type header' do
        [public_auth_info, asymmetric_auth_info, backend_services_auth_info].each do |credentials|
          expect(credentials.oauth2_refresh_headers).to eq('Content-Type' => 'application/x-www-form-urlencoded')
        end
      end
    end
  end

  describe '#signed_jwt' do
    context 'when kid is present' do
      it 'returns valid JWT signed with keys having the correct algorithm and kid' do
        jwt = asymmetric_auth_info.signed_jwt
        claims, header = JWT.decode(jwt, nil, false)

        expect(header['alg']).to eq(asymmetric_auth_info.encryption_algorithm)
        expect(header['typ']).to eq('JWT')
        expect(header['kid']).to eq(asymmetric_auth_info.kid)
        expect(claims['iss']).to eq(asymmetric_auth_info.client_id)
        expect(claims['aud']).to eq(asymmetric_auth_info.token_url)
        expect(claims['sub']).to eq(asymmetric_auth_info.client_id)
        expect(claims['exp']).to be_present
        expect(claims['jti']).to be_present
      end
    end

    context 'when kid is missing' do
      it 'returns valid JWT igned with keys having the correct algorithm' do
        asymmetric_auth_info.kid = nil
        jwt = asymmetric_auth_info.signed_jwt
        claims, header = JWT.decode(jwt, nil, false)

        expect(header['alg']).to eq(asymmetric_auth_info.encryption_algorithm)
        expect(header['typ']).to eq('JWT')
        expect(header['kid']).to be_present
        expect(claims['iss']).to eq(asymmetric_auth_info.client_id)
        expect(claims['aud']).to eq(asymmetric_auth_info.token_url)
        expect(claims['sub']).to eq(asymmetric_auth_info.client_id)
        expect(claims['exp']).to be_present
        expect(claims['jti']).to be_present
      end
    end

    it 'throws exception when kid not found for the given algorithm' do
      asymmetric_auth_info.kid = 'random'
      expect do
        asymmetric_auth_info.signed_jwt
      end.to raise_error(Inferno::Exceptions::AssertionException)
    end
  end

  describe '#update_from_response_body' do
    before { auth_info.add_to_client(client) }

    it 'updates the refresh token if a new one is received' do
      response_body = {
        access_token: 'NEW_ACCESS_TOKEN',
        refresh_token: 'NEW_REFRESH_TOKEN',
        expires_in: 3600
      }
      request = OpenStruct.new(response_body: response_body.to_json)

      auth_info.update_from_response_body(request)

      expect(auth_info.refresh_token).to eq('NEW_REFRESH_TOKEN')
    end

    it 'does not update the refresh token if none is received' do
      response_body = {
        access_token: 'NEW_ACCESS_TOKEN',
        expires_in: 3600
      }
      request = OpenStruct.new(response_body: response_body.to_json)

      auth_info.update_from_response_body(request)

      expect(auth_info.refresh_token).to eq('REFRESH_TOKEN')
    end
  end
end
