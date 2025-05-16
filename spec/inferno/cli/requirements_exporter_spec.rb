require_relative '../../../lib/inferno/apps/cli/requirements_exporter'

RSpec.describe Inferno::CLI::RequirementsExporter do
  let(:exporter) { described_class.new }

  before do
    allow(exporter).to receive_messages(test_kit_name: 'reqirements_test_kit',
                                        base_requirements_folder: 'spec/fixtures/requirements')
  end

  describe '#input_requirement_sets' do
    it 'uses the requirement set id as the Hash key' do
      requirement_sets = exporter.input_requirement_sets

      expect(requirement_sets.length).to eq(1)
      expect(requirement_sets.keys.first).to eq('requirement_set_id')
    end

    it 'assigns the requirement rows to an Array of Hashes' do
      requirement_sets = exporter.input_requirement_sets

      requirements = requirement_sets.values.first

      expect(requirements).to be_an(Array)

      expect(requirements).to all(be_a(Hash))

      expect(requirements).to all(include(*described_class::INPUT_HEADERS))
    end
  end

  describe '#new_requriments_csv' do
    before do
      allow(exporter).to receive(:base_requirements_folder).and_return('spec/fixtures/requirements')
    end

    it 'generates a CSV with the correct columns' do
      csv = exporter.new_requirements_csv

      parsed_csv = CSV.parse(csv)

      # The added BOM makes the first column header not match
      expect(parsed_csv.first.first).to_not eq(described_class::REQUIREMENTS_OUTPUT_HEADERS.first)
      expect(parsed_csv.first.slice(1..-1)).to eq(described_class::REQUIREMENTS_OUTPUT_HEADERS.slice(1..-1))

      expect(parsed_csv.length).to eq(exporter.input_requirement_sets.values.first.length + 1)
    end
  end

  describe '#new_planned_not_tested_csv' do
    it 'generates a CSV with the correct columns' do
      csv = exporter.new_planned_not_tested_csv

      parsed_csv = CSV.parse(csv)

      # The added BOM makes the first column header not match
      expect(parsed_csv.first.first).to_not eq(described_class::PLANNED_NOT_TESTED_OUTPUT_HEADERS.first)
      expect(parsed_csv.first.slice(1..-1)).to eq(described_class::PLANNED_NOT_TESTED_OUTPUT_HEADERS.slice(1..-1))

      expect(parsed_csv.length).to eq(3)
    end
  end
end
