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

    context 'when a Sub-Requirement(s) cell is an email hyperlink' do
      # Excel auto-links "package@version" text as an email address, and roo
      # emits a hyperlinked cell as its URL in to_csv, so the value arrives
      # with a "mailto:" prefix. Cell F8 of the fixture has such a link.
      let(:sub_requirement) { 'hl7.fhir.us.davinci-hrex_1.0.0@21-32' }

      it 'receives the mailto: prefixed value from roo' do
        worksheet = Roo::Spreadsheet.open(exporter.available_input_worksheets.first)
        raw_sub_requirements =
          CSV.parse(worksheet.sheet('Requirements').to_csv, headers: true)
            .map { |row| row['Sub-Requirement(s)'] }
            .compact

        expect(raw_sub_requirements).to include("mailto:#{sub_requirement}")
      end

      it 'strips the mailto: prefix' do
        sub_requirements =
          exporter.input_requirement_sets.values.first
            .map { |row| row['Sub-Requirement(s)'] }
            .compact

        expect(sub_requirements).to include(sub_requirement)
        expect(sub_requirements.grep(/\Amailto:/)).to be_empty
      end
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

    it 'does not carry mailto: prefixes into the Sub-Requirement(s) column' do
      parsed_csv = CSV.parse(exporter.new_requirements_csv, headers: true)
      sub_requirements = parsed_csv.map { |row| row['Sub-Requirement(s)'] }.compact

      expect(sub_requirements).to include('hl7.fhir.us.davinci-hrex_1.0.0@21-32')
      expect(sub_requirements.grep(/\Amailto:/)).to be_empty
    end
  end
end
