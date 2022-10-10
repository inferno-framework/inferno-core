RSpec.describe Inferno::Repositories::TestSessions do
  let(:repo) { described_class.new }

  describe '#create' do
    let(:test_suite_id) { 'basic' }

    context 'with valid params' do
      it 'persists the test session' do
        test_session = repo.create(test_suite_id: test_suite_id)
        expect(test_session).to be_a(Inferno::Entities::TestSession)
        expect(test_session.test_suite.ancestors).to include(Inferno::Entities::TestSuite)
      end
    end

    context 'when the suite cannot be found' do
      it 'raises an error' do
        expect { repo.create(test_suite_id: 'ABC') }.to raise_error(Sequel::ValidationFailed, /ABC/)
      end
    end
  end

  describe '#find' do
    let(:test_session) { repo_create(:test_session) }

    context 'when the record can be found' do
      it 'returns a TestSession' do
        record = repo.find(test_session.id)
        expect(record).to be_a(Inferno::Entities::TestSession)
        expect(record.id).to eq(test_session.id)
      end
    end

    context 'when the record can not be found' do
      it 'returns nil' do
        record = repo.find(SecureRandom.uuid)

        expect(record).to be_nil
      end
    end
  end

  describe '#results_for_test_session' do
    let(:test_run) { repo_create(:test_run) }
    let(:test_session) { test_run.test_session }
    let!(:result) { repo_create(:result, test_run: test_run, message_count: 2, request_count: 2) }
    let(:messages) { result.messages }
    let(:requests) { result.requests }

    it 'returns the results for a test session' do
      results = repo.results_for_test_session(test_session.id)

      expect(results.length).to eq(1)
      expect(results.first.id).to eq(result.id)
    end

    it 'includes messages' do
      results = repo.results_for_test_session(test_session.id)

      expect(results.first.messages.length).to eq(messages.length)
    end

    it 'includes requests' do
      results = repo.results_for_test_session(test_session.id)

      expect(results.first.requests.length).to eq(requests.length)
    end
  end
end
