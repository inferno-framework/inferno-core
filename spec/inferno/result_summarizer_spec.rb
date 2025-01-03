require_relative '../../lib/inferno/result_summarizer'

RSpec.describe Inferno::ResultSummarizer do
  let(:passing_result) { repo_create(:result, result: 'pass') }
  let(:failing_result) { repo_create(:result, result: 'fail') }
  let(:waiting_result) { repo_create(:result, result: 'wait') }

  context 'when all results are required' do
    it 'returns the highest priority result' do
      result = described_class.new([passing_result, failing_result]).summarize

      expect(result).to eq('fail')
    end
  end

  context 'when all results are optional' do
    it 'prioritizes passing over failing when a result passes' do
      allow(passing_result).to receive(:optional?).and_return(true)
      allow(failing_result).to receive(:optional?).and_return(true)
      result = described_class.new([passing_result, failing_result]).summarize

      expect(result).to eq('pass')
    end
  end

  context 'when there are required and optional results' do
    it 'returns the highest priority required result' do
      allow(failing_result).to receive(:optional?).and_return(true)
      result = described_class.new([passing_result, failing_result]).summarize

      expect(result).to eq('pass')
    end

    it 'returns "wait" if an optional result is waiting' do
      allow(waiting_result).to receive(:optional?).and_return(true)
      result = described_class.new([passing_result, waiting_result]).summarize

      expect(result).to eq('wait')
    end
  end
end
