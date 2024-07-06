RSpec.describe Inferno::DSL::AuthInfo do
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
  let(:auth_info) { described_class.new(full_params) }
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
end
