require_relative '../../../lib/inferno/utils/persist_inputs'

RSpec.describe Inferno::Utils::PersistInputs do
  describe '#persist_inputs' do
    let(:dummy_class) do
      Class.new do
        include Inferno::Utils::PersistInputs
      end
    end
    let(:dummy) { dummy_class.new }
    let(:suite) { BasicTestSuite::Suite }
    let(:test_sessions_repo) { Inferno::Repositories::TestSessions.new }
    let(:session_data_repo) { Inferno::Repositories::SessionData.new }

    it 'saves inputs to db' do
      test_session = test_sessions_repo.create(test_suite_id: suite.id)

      test_run = create(:test_run, test_session:)
      test_run.test_session_id = test_session.id

      params = {
        test_session_id: test_session.id,
        test_suite_id: suite.id,
        inputs: [
          { name: 'input1', value: 'persist me' }
        ]
      }

      dummy.persist_inputs(session_data_repo, params, test_run)
      persisted_data = session_data_repo.load(test_session_id: test_run.test_session_id, name: 'input1')

      expect(persisted_data).to eq('persist me')
    end

    it 'saves known inputs when given unknown extraneous inputs' do
      test_session = test_sessions_repo.create(test_suite_id: suite.id)

      test_run = create(:test_run, test_session:)
      test_run.test_session_id = test_session.id

      params = {
        test_session_id: test_session.id,
        test_suite_id: suite.id,
        inputs: [
          { name: 'extraneous', value: 'omit me' },
          { name: 'input1', value: 'persist me' }
        ]
      }

      expect { dummy.persist_inputs(session_data_repo, params, test_run) }.to_not raise_error

      persisted_data = session_data_repo.load(test_session_id: test_run.test_session_id, name: 'input1')
      expect(persisted_data).to eq('persist me')
    end
  end
end
