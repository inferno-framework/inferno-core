RSpec.describe Inferno::DSL::OAuthCredentials do
  let(:full_params) do
    {
      access_token: 'ACCESS_TOKEN',
      refresh_token: 'REFRESH_TOKEN',
      token_url: 'http://example.com/token',
      client_id: 'CLIENT_ID',
      client_secret: 'CLIENT_SECRET',
      token_retrieval_time: DateTime.now,
      expires_in: 3600,
      name: 'NAME'
    }
  end
  let(:credentials) { described_class.new(full_params) }

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
    let(:client) { FHIR::Client.new('http://example.com') }

    it 'sets the oauth credentials on the client' do
      credentials.add_to_client(client)

      expect(client.oauth_credentials).to eq(credentials)
    end

    context 'when a bearer token is present' do
      it 'sets the bearer token on the client' do
        credentials.add_to_client(client)

        expect(client.security_headers['Authorization']).to eq("Bearer #{credentials.access_token}")
      end
    end

    context 'when no bearer token is present' do
      it 'does not set the bearer token on the client' do
        client.set_bearer_token('BEARER_TOKEN')
        credentials.access_token = nil
        credentials.add_to_client(client)

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
      credentials.access_token = nil

      expect(credentials.need_to_refresh?).to be(false)
    end

    it 'returns false if there is no refresh token' do
      credentials.refresh_token = nil

      expect(credentials.need_to_refresh?).to be(false)
    end

    it 'returns true if there is no expires_in' do
      credentials.expires_in = nil

      expect(credentials.need_to_refresh?).to be(true)
    end

    it 'returns true if the token has will expire in under a minute' do
      credentials.expires_in = 59

      expect(credentials.need_to_refresh?).to be(true)
    end

    it 'returns true if the token has expired' do
      credentials.token_retrieval_time = 2.hours.ago

      expect(credentials.need_to_refresh?).to be(true)
    end

    it 'returns false if the token is valid for over a minute' do
      credentials.expires_in = 61

      expect(credentials.need_to_refresh?).to be(false)
    end
  end

  describe '#able_to_refresh?' do
    it 'returns true if a refresh token and token url are present' do
      expect(credentials.able_to_refresh?).to be(true)
    end

    it 'returns false if the refresh token or token url are missing' do
      [:refresh_token, :token_url].each do |field|
        params = full_params.merge("#{field}": nil)

        expect(described_class.new(params).need_to_refresh?).to be(false)
      end
    end
  end

  describe '#oauth2_refresh_headers' do
    context 'when a client id and secret are present' do
      it 'returns a hash with Content-Type and Authorization headers' do
        expect(credentials.oauth2_refresh_headers).to include('Authorization', 'Content-Type')
      end
    end

    context 'when a client secret is not present' do
      it 'returns a hash with a Content-Type header' do
        credentials.client_secret = nil
        expect(credentials.oauth2_refresh_headers).to eq('Content-Type' => 'application/x-www-form-urlencoded')
      end
    end
  end
end
