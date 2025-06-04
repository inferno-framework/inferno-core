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

  describe '#insert' do
    let(:records) { repo.all }

    context 'when id is the same as database_id' do
      it 'inserts a new suite into the repository' do
        new_suite = Class.new(Inferno::TestSuite)
        new_suite.id('suite_id')
        expect { repo.insert(new_suite) }.to change(records, :size).by(1)
        expect(records).to include(new_suite)
      end

      it 'raises an error if the id already exist' do
        expect { repo.insert(suite) }.to raise_error(Inferno::Exceptions::DuplicateEntityIdException, /already exists/)
      end
    end

    context 'when id is different from database_id (id too long)' do
      it 'inserts the suite and indexes by both id and database_id' do
        long_suite = Class.new(Inferno::TestSuite)
        long_suite.id('a' * 260)

        expect { repo.insert(long_suite) }.to change(records, :size).by(1)
        expect(repo.find(long_suite.id)).to eq(long_suite)
        expect(repo.find(long_suite.database_id)).to eq(long_suite)
      end

      it 'raises a DuplicateEntityIdException for database-safe id' do
        allow(Digest::SHA1).to receive(:hexdigest).and_return('deadbeef00')

        suite1 = Class.new(Inferno::TestSuite) do
          id 'a' * 256
        end
        suite2 = Class.new(Inferno::TestSuite) do
          id "#{'a' * 255}b"
        end

        repo.insert(suite1)

        expect { repo.insert(suite2) }.to raise_error(
          Inferno::Exceptions::DuplicateEntityIdException, /database_id: `#{suite2.database_id}`' already exists/
        )
      end
    end
  end

  describe '#remove' do
    context 'when id is the same as database_id' do
      it 'removes the suite from the repository' do
        new_suite = Class.new(Inferno::TestSuite)
        new_suite.id('new_suite_id')

        repo.insert(new_suite)

        expect(repo.find(new_suite.id)).to eq(new_suite)

        repo.remove(new_suite)

        expect(repo.find(new_suite.id)).to be_nil
      end
    end

    context 'when id is different from database_id (id too long)' do
      it 'removes the suite from both id and database_id indexes' do
        new_suite = Class.new(Inferno::TestSuite)
        new_suite.id('new_suite_id' * 255)
        repo.insert(new_suite)

        expect(repo.find(new_suite.id)).to eq(new_suite)
        expect(repo.find(new_suite.database_id)).to eq(new_suite)

        repo.remove(new_suite)

        expect(repo.find(new_suite.id)).to be_nil
        expect(repo.find(new_suite.database_id)).to be_nil
      end
    end
  end
end
