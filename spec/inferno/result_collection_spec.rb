require_relative '../../lib/inferno/result_collection'

RSpec.describe Inferno::ResultCollection do
  let(:runner) { Inferno::TestRunner.new(test_session:, test_run:) }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'custom_result_suite') }
  let(:results_repo) { Inferno::Repositories::Results.new }
  let(:suite) { CustomResult::Suite }
  let(:test_run) do
    repo_create(:test_run, runnable: { test_suite_id: suite.id }, test_session_id: test_session.id)
  end
  let(:suite_children) { suite.children }
  let(:child_results) { results_repo.current_results_for_test_session_and_runnables(test_session.id, suite_children) }
  let(:result_collection) { described_class.new(child_results) }

  before do
    runner.run(suite)
  end

  describe '#initialize' do
    it 'initializes with an array of results' do
      expect(result_collection.results).to eq(child_results)
    end
  end

  describe '#[]' do
    context 'when accessing by index' do
      it 'returns the result at the given index' do
        expect(result_collection[0]).to eq(child_results.first)
        expect(result_collection[1]).to eq(child_results.second)
        expect(result_collection[2]).to eq(child_results.third)
      end
    end

    context 'when accessing by runnable ID' do
      context 'when using full ID' do
        it 'returns the result with the matching runnable ID' do
          expect(result_collection[suite_children.first.id]).to eq(child_results.first)
        end
      end

      context 'when using partial ID' do
        it 'returns the result with the runnable ID ending with the partial ID' do
          partial_id = suite_children.first.id.split('-').last
          expect(result_collection[partial_id]).to eq(child_results.first)
        end
      end

      it 'returns nil if no result matches the runnable ID' do
        expect(result_collection['non_existent_id']).to be_nil
      end
    end
  end

  describe '#<<' do
    let(:new_result) { repo_create(:result, result: 'pass') }

    it 'adds a new result to the collection' do
      expect { result_collection << new_result }.to change { result_collection.results.size }.by(1)
      expect(result_collection.results).to include(new_result)
    end
  end

  describe '#each' do
    it 'iterates over each result in the collection' do
      expect do |b|
        result_collection.each(&b)
      end.to yield_successive_args(child_results.first, child_results.second, child_results.third)
    end
  end

  describe '#required_results' do
    it 'returns all required results' do
      expect(result_collection.required_results).to contain_exactly(child_results.first)
    end
  end

  describe '#optional_results' do
    it 'returns all optional results' do
      expect(result_collection.optional_results).to contain_exactly(child_results.second, child_results.third)
    end
  end
end
