RSpec.describe Inferno::Repositories::ValidatorSessions do
  let(:repo) { described_class.new }
  let(:validator_name) { 'basic_name' }
  let(:test_suite_id) { 'basic_suite' }
  let(:validator_session_id1) { 'basic_validator1' }
  let(:validator_session_id2) { 'basic_validator2' }
  let(:suite_options1) { [Inferno::DSL::SuiteOption.new(id: :ig_version, value: '1')] }
  let(:suite_options2) { [Inferno::DSL::SuiteOption.new(id: :ig_version, value: '2')] }
  let(:session1_params) do
    {
      validator_session_id: validator_session_id1,
      validator_name:,
      test_suite_id:,
      suite_options: suite_options1
    }
  end
  let(:session2_params) do
    {
      validator_session_id: validator_session_id2,
      validator_name:,
      test_suite_id:,
      suite_options: suite_options2
    }
  end
  let(:session3_params) do
    {
      validator_session_id: validator_session_id1,
      validator_name: 'new_name',
      test_suite_id:,
      suite_options: suite_options1
    }
  end

  describe '#create' do
    before do
      repo.save(session1_params)
    end

    context 'with valid params' do
      it 'persists data' do
        record = repo.db.first
        expect(repo.db.count).to eq(1)
        expect(record[:validator_session_id]).to eq(validator_session_id1)
        expect(record[:validator_name]).to eq(validator_name)
        expect(record[:test_suite_id]).to eq(test_suite_id)
      end

      it 'creates a separate record given a different validator session id' do
        repo.save(session2_params)
        record = repo.db.all[1]
        expect(repo.db.count).to eq(2)
        expect(record[:validator_session_id]).to eq(validator_session_id2)
        expect(record[:validator_name]).to eq(validator_name)
        expect(record[:test_suite_id]).to eq(test_suite_id)
      end

      it 'overwrites an existing record given the same validator session id' do
        repo.save(session3_params)
        record = repo.db.first
        expect(repo.db.count).to eq(1)
        expect(record[:validator_session_id]).to eq(validator_session_id1)
        expect(record[:validator_name]).to eq('new_name')
        expect(record[:test_suite_id]).to eq(test_suite_id)
      end
    end
  end

  describe '#find' do
    before do
      repo.save(session1_params)
    end

    it 'single record' do
      record = repo.db.first
      suite_options = JSON.generate(session1_params[:suite_options].map(&:to_hash))
      validator_id = repo.find_validator_session_id(session1_params[:test_suite_id],
                                                    session1_params[:validator_name], suite_options)
      expect(record[:validator_session_id]).to eq(validator_id)
    end

    it 'two record, discriminated by suite options' do
      repo.save(session2_params)
      record = repo.db.first
      record2 = repo.db.all[1]
      suite_options = JSON.generate(session1_params[:suite_options].map(&:to_hash))
      suite_options2 = JSON.generate(session2_params[:suite_options].map(&:to_hash))
      validator_id = repo.find_validator_session_id(session1_params[:test_suite_id],
                                                    session1_params[:validator_name], suite_options)
      validator_id2 = repo.find_validator_session_id(session2_params[:test_suite_id],
                                                     session2_params[:validator_name], suite_options2)
      expect(record[:validator_session_id]).to eq(validator_id)
      expect(record2[:validator_session_id]).to eq(validator_id2)
    end
  end
end
