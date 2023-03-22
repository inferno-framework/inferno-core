require_relative '../../../lib/inferno/repositories/session_data'

RSpec.describe Inferno::Repositories::SessionData do
  let(:repo) { described_class.new }
  let(:test_session) { repo_create(:test_session) }
  let(:value) { 'VALUE' }
  let(:name) { 'name' }

  before do
    repo.save(
      test_session_id: test_session.id,
      name:,
      value:,
      type: 'text'
    )
  end

  describe '#save' do
    let(:new_value) { 'NEW_VALUE' }

    it 'persists data' do
      record = repo.db.first
      expect(record[:value]).to eq(value)
      expect(record[:name]).to eq(name)
      expect(record[:test_session_id]).to eq(test_session.id)
    end

    it 'overwrites existing data for a test session and name' do
      repo.save(
        test_session_id: test_session.id,
        name:,
        value: new_value,
        type: 'text'
      )

      expect(repo.db.count).to eq(1)

      record = repo.db.first
      expect(record[:value]).to eq(new_value)
      expect(record[:name]).to eq(name)
      expect(record[:test_session_id]).to eq(test_session.id)
    end

    it 'does not overwrite data for different test sessions' do
      test_session2 = repo_create(:test_session)
      repo.save(
        test_session_id: test_session2.id,
        name:,
        value:,
        type: 'text'
      )

      expect(repo.db.count).to eq(2)
    end

    it 'does not overwrite data for different names' do
      name2 = 'name_2'
      repo.save(
        test_session_id: test_session.id,
        name: name2,
        value:,
        type: 'text'
      )

      expect(repo.db.count).to eq(2)
    end

    context 'with oauth_credentials' do
      it 'stores the serialized credentials' do
        credentials = Inferno::DSL::OAuthCredentials.new(access_token: 'TOKEN', client_id: 'CLIENT_ID')
        name = 'creds'
        params = {
          name:,
          value: credentials,
          type: 'oauth_credentials',
          test_session_id: test_session.id
        }

        repo.save(params)

        persisted_value = repo.class.db.where(name:).first[:value]
        expect(persisted_value).to eq(credentials.to_s)
      end

      it 'accepts a json string' do
        credentials = Inferno::DSL::OAuthCredentials.new(access_token: 'TOKEN', client_id: 'CLIENT_ID')
        name = 'creds'
        params = {
          name:,
          value: credentials.to_s,
          type: 'oauth_credentials',
          test_session_id: test_session.id
        }

        repo.save(params)

        persisted_value = repo.class.db.where(name:).first[:value]
        expect(JSON.parse(persisted_value)).to include(JSON.parse(credentials.to_s))
      end
    end

    context 'with checkboxes' do
      it 'stores the serialized input' do
        value = ['abc', 'def']
        name = 'checkbox'
        params = {
          name:,
          value:,
          type: 'checkbox',
          test_session_id: test_session.id
        }

        repo.save(params)

        persisted_value = repo.class.db.where(name:).first[:value]
        expect(persisted_value).to eq(value.to_json)
      end

      it 'stores a json string' do
        value = ['abc', 'def'].to_json
        name = 'checkbox'
        params = {
          name:,
          value:,
          type: 'checkbox',
          test_session_id: test_session.id
        }

        repo.save(params)

        persisted_value = repo.class.db.where(name:).first[:value]
        expect(persisted_value).to eq(value)
      end
    end
  end

  describe '#load' do
    it 'returns the value for an piece of data' do
      data = repo.load(test_session_id: test_session.id, name:)

      expect(data).to eq(value)
    end

    it 'returns nil if the data cannot be found' do
      data = repo.load(test_session_id: test_session.id, name: 'abc')

      expect(data).to be_nil
    end

    context 'with oauth_credentials' do
      it 'returns an OAuthCredentials instance' do
        raw_value = Inferno::DSL::OAuthCredentials.new(access_token: 'TOKEN', client_id: 'CLIENT_ID').to_s
        name = 'creds'
        repo.save(
          name:,
          value: raw_value,
          type: 'text',
          test_session_id: test_session.id
        )

        value = repo.load(test_session_id: test_session.id, name:, type: 'oauth_credentials')

        expect(value).to be_a(Inferno::DSL::OAuthCredentials)
        expect(value.to_s).to eq(raw_value)
      end
    end

    context 'with checkboxes' do
      it 'returns an array' do
        raw_value = ['abc', 'def']
        name = 'checkbox'
        repo.save(
          name:,
          value: raw_value,
          type: 'checkbox',
          test_session_id: test_session.id
        )

        value = repo.load(test_session_id: test_session.id, name:, type: 'checkbox')

        expect(value).to be_an(Array)
        expect(value).to eq(raw_value)
      end
    end
  end
end
