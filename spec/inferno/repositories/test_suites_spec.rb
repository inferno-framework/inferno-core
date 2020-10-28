RSpec.describe Inferno::Repositories::TestSuites do
  let(:repo) { described_class.new }
  let(:suite) { BasicTestSuite::Suite }

  describe '#all' do
    it 'returns an array of test suites' do
      records = repo.all

      expect(records).to be_an(Array)
      expect(records).to include(suite)
    end
  end

  describe '#find' do
    it 'returns the correct test suite' do
      record = repo.find(suite.id)

      expect(record).to eq(suite)
    end

    it 'returns nil when the record can not be found' do
      record = repo.find(SecureRandom.uuid)

      expect(record).to be_nil
    end
  end
end
