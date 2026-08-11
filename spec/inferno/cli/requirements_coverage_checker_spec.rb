require_relative '../../../lib/inferno/apps/cli/requirements_coverage_checker'

RSpec.describe Inferno::CLI::RequirementsCoverageChecker do
  let(:test_suite_id) { 'ig_requirements' }
  let(:checker) { described_class.new(test_suite_id) }

  before do
    allow(checker).to receive_messages(
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

  describe '#run' do
    let(:mock_exporter) do
      instance_double(Inferno::CLI::RequirementsExporter, base_requirements_folder: 'tmp/requirements')
    end

    before do
      allow(Inferno::CLI::RequirementsExporter).to receive(:new).and_return(mock_exporter)
      allow(checker).to receive(:puts)
      allow(File).to receive(:exist?).with(checker.output_file_path).and_return(false)
      allow(File).to receive(:read).with(checker.output_file_path)
      allow(FileUtils).to receive(:mkdir_p)
      allow(File).to receive(:write)
    end

    it 'runs to completion' do
      expect { checker.run }.to_not raise_error
      expect(File).to have_received(:write).with(checker.output_file_path, checker.new_csv)
    end
  end
end
