RSpec.describe Inferno::Repositories::ValidatorSessions do
  let(:repo) { described_class.new }
  let(:validator_name) { 'basic_name' }
  let(:test_suite_id) { 'basic_suite' }
  let(:validator_session_id1) { 'basic_validator1' }
  let(:validator_session_id2) { 'basic_validator2' }
  let(:validator_session_id3) { 'basic_validator3' }
  let(:suite_options1) { { ig_version: '1', us_core_version: '4' } }
  let(:suite_options2) { { ig_version: '2' } }
  let(:suite_options_alt) { { us_core_version: '4', ig_version: '1' } }
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
      validator_session_id: validator_session_id3,
      validator_name:,
      test_suite_id:,
      suite_options: suite_options1
    }
  end
  let(:session_params_alt1) do
    {
      validator_session_id: validator_session_id2,
      validator_name:,
      test_suite_id:,
      suite_options: suite_options_alt
    }
  end
  let(:session4_params) do
    {
      validator_session_id: validator_session_id2,
      validator_name: 'alt name',
      test_suite_id:,
      suite_options: suite_options1
    }
  end
  let(:session5_params) do
    {
      validator_session_id: validator_session_id2,
      validator_name:,
      test_suite_id: 'alt id',
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
        expect(record[:validator_session_id]).to eq(validator_session_id3)
        expect(record[:validator_name]).to eq('basic_name')
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
      # suite_options = JSON.generate(session1_params[:suite_options].map(&:to_hash))
      validator_id = repo.find_validator_session_id(session1_params[:test_suite_id],
                                                    session1_params[:validator_name], session1_params[:suite_options])
      expect(record[:validator_session_id]).to eq(validator_id)
    end

    it 'two records, discriminated by suite options' do
      repo.save(session2_params)
      record = repo.db.first
      record2 = repo.db.all[1]
      validator_id = repo.find_validator_session_id(session1_params[:test_suite_id],
                                                    session1_params[:validator_name], session1_params[:suite_options])
      validator_id2 = repo.find_validator_session_id(session2_params[:test_suite_id],
                                                     session2_params[:validator_name], session2_params[:suite_options])
      expect(record[:validator_session_id]).to eq(validator_id)
      expect(record2[:validator_session_id]).to eq(validator_id2)
    end

    it 'updated validator session id, when reverse order suite options cause overwrite' do
      repo.save(session_params_alt1)
      record = repo.db.first
      validator_id = repo.find_validator_session_id(session1_params[:test_suite_id],
                                                    session1_params[:validator_name], session1_params[:suite_options])
      validator_id_alt = repo.find_validator_session_id(session_params_alt1[:test_suite_id],
                                                        session_params_alt1[:validator_name],
                                                        session_params_alt1[:suite_options])
      expect(validator_session_id2).to eq(validator_id)
      expect(validator_session_id2).to eq(validator_id_alt)
      expect(validator_session_id2).to eq(record[:validator_session_id])
    end

    it 'two records, discriminate by name' do
      repo.save(session4_params)
      record = repo.db.first
      record4 = repo.db.all[1]
      validator_id = repo.find_validator_session_id(session1_params[:test_suite_id],
                                                    session1_params[:validator_name], session1_params[:suite_options])
      validator_id4 = repo.find_validator_session_id(session4_params[:test_suite_id],
                                                     session4_params[:validator_name], session4_params[:suite_options])
      expect(record[:validator_session_id]).to eq(validator_id)
      expect(record4[:validator_session_id]).to eq(validator_id4)
    end

    it 'two records, discriminate by suite id' do
      repo.save(session5_params)
      record = repo.db.first
      record5 = repo.db.all[1]
      validator_id = repo.find_validator_session_id(session1_params[:test_suite_id],
                                                    session1_params[:validator_name], session1_params[:suite_options])
      validator_id2 = repo.find_validator_session_id(session5_params[:test_suite_id],
                                                     session5_params[:validator_name], session5_params[:suite_options])
      expect(record[:validator_session_id]).to eq(validator_id)
      expect(record5[:validator_session_id]).to eq(validator_id2)
    end
  end
end
