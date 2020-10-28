RSpec.describe Inferno::Repositories::TestRuns do
  let(:repo) { described_class.new }
  let(:test_session) { test_run.test_session }
  let(:test_run) { repo_create(:test_run) }

  describe '#create' do
    let(:test_group_id) { 'BasicTestSuite::AbcGroup' }
    let(:test_run_definition) do
      {
        test_session_id: test_session.id,
        test_group_id: test_group_id
      }
    end

    context 'with valid params' do
      it 'persists the test run' do
        test_run = repo.create(test_run_definition)

        expect(test_run).to be_a(Inferno::Entities::TestRun)

        test_run_definition.each do |key, value|
          expect(test_run.send(key)).to eq(value)
        end
      end
    end

    context 'when the runnable cannot be found' do
      it 'raises an error' do
        invalid_params = test_run_definition.merge(test_group_id: 'ABC')

        expect { repo.create(invalid_params) }.to raise_error(Sequel::ValidationFailed, /ABC/)
      end
    end

    context 'when the test_session cannot be found' do
      it 'raises an error' do
        invalid_params = test_run_definition.merge(test_session_id: 'ABC')

        expect { repo.create(invalid_params) }.to raise_error(Sequel::ForeignKeyConstraintViolation)
      end
    end
  end

  describe '#find' do
    context 'when the record can be found' do
      it 'returns a TestRun' do
        record = repo.find(test_run.id)
        expect(record).to be_a(Inferno::Entities::TestRun)
        expect(record.id).to eq(test_run.id)
      end
    end

    context 'when the record can not be found' do
      it 'returns nil' do
        record = repo.find(SecureRandom.uuid)

        expect(record).to be_nil
      end
    end
  end

  describe '#results_for_test_run' do
    let!(:result) { repo_create(:result, test_run_id: test_run.id, message_count: 2, request_count: 2) }
    let(:messages) { result.messages }
    let(:requests) { result.requests }

    it 'returns the results for a test run' do
      results = repo.results_for_test_run(test_run.id)

      expect(results.length).to eq(1)
      expect(results.first.id).to eq(result.id)
    end

    it 'includes messages' do
      results = repo.results_for_test_run(test_run.id)

      expect(results.first.messages.length).to eq(messages.length)
    end

    it 'includes requests' do
      results = repo.results_for_test_run(test_run.id)

      expect(results.first.requests.length).to eq(requests.length)
    end
  end
end
