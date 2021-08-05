RSpec.describe Inferno::Repositories::SessionData do
  let(:repo) { described_class.new }
  let(:test_session) { repo_create(:test_session) }
  let(:value) { 'VALUE' }
  let(:name) { 'name' }

  before do
    repo.save(
      test_session_id: test_session.id,
      name: name,
      value: value
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
        name: name,
        value: new_value
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
        name: name,
        value: value
      )

      expect(repo.db.count).to eq(2)
    end

    it 'does not overwrite data for different names' do
      name2 = 'name_2'
      repo.save(
        test_session_id: test_session.id,
        name: name2,
        value: value
      )

      expect(repo.db.count).to eq(2)
    end
  end

  describe '#load' do
    it 'returns the value for an piece of data' do
      data = repo.load(test_session_id: test_session.id, name: name)

      expect(data).to eq(value)
    end

    it 'returns nil if the data cannot be found' do
      data = repo.load(test_session_id: test_session.id, name: 'abc')

      expect(data).to be_nil
    end
  end
end
