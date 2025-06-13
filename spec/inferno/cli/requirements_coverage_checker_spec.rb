require_relative '../../../lib/inferno/apps/cli/requirements_coverage_checker'

RSpec.describe Inferno::CLI::RequirementsCoverageChecker do
  let(:test_suite_id) { 'ig_requirements' }
  let(:checker) { described_class.new(test_suite_id) }

  before do
    allow(checker).to receive_messages(
                        # base_requirements_folder: 'spec/fixtures/requirements',
                        output_file_path: 'spec/fixtures/requirements/ig_requirements_requirements_coverage.csv'
                      )
  end

  describe '#new_csv' do
    it 'generates a coverage csv with all fields' do
      expected_csv = File.read('spec/fixtures/requirements/ig_requirements_requirements_coverage.csv')
      generated_csv = checker.new_csv

      expect(generated_csv).to eq(expected_csv)
    end
  end
end
