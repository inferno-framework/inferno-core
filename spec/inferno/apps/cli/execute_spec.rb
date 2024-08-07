require_relative '../../../../lib/inferno/apps/cli/execute.rb'

RSpec.describe Inferno::CLI::Execute do
  
  describe '#thor_hash_to_inputs_array' do
    let(:hash) { {url: 'https://example.com'} }

    it 'converts hash to array' do
      result = described_class.new.thor_hash_to_inputs_array(hash)
      expect(result.class).to eq(Array)
    end

    it 'returns proper inputs array' do
      result = described_class.new.thor_hash_to_inputs_array(hash)
      expect(result).to eq([{name: :url, value: 'https://example.com'}])
    end
  end

  describe '#create_params' do
    let(:test_suite) { BasicTestSuite::Suite }
    let(:test_sessions_repo) { Inferno::Repositories::TestSessions.new }

    it 'returns test run params' do
      instance = described_class.new
      allow(instance).to receive(:options).and_return({inputs: {url: 'https://example.com'}})
      test_session = test_sessions_repo.create(test_suite_id: test_suite.id)

      result = instance.create_params(test_session, test_suite)
      expect(result).to eq({test_session_id: test_session.id, test_suite_id: 'basic', inputs: [{name: :url, value: 'https://example.com'}]})
    end
  end

  describe '#serialize' do
    it 'handles an array of test results' do
      pending 'TODO'
    end
  end

  describe '#verbose_print' do
    it 'works' do
      pending 'TODO'
    end
  end

  describe '#verbose_puts' do
    it 'works' do
      pending 'TODO'
    end
  end

  describe '#fetch_test_id' do
    it 'works' do
      pending 'TODO'
    end
  end

  describe '#format_messages' do
    it 'works' do
      pending 'TODO'
    end
  end

  describe '#format_requests' do
    it 'works' do
      pending 'TODO'
    end
  end

  describe '#format_inputs' do
    it 'works' do
      pending 'TODO'
    end
  end

  describe '#format_outputs' do
    it 'works' do
      pending 'TODO'
    end
  end

  describe '#print_error_and_exit' do
    it 'works' do
      pending 'TODO'
    end
  end
end
