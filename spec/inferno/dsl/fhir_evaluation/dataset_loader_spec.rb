RSpec.describe Inferno::DSL::FHIREvaluation::DatasetLoader do
  let(:patient_json) { FHIR::Patient.new(id: 'patient-1').to_json }
  let(:observation_json) { FHIR::Observation.new(id: 'observation-1', status: 'final').to_json }
  let(:non_fhir_json) { '{"not": "a fhir resource"}' }

  describe '.from_contents' do
    it 'parses each json string into a FHIR resource and skips ones that are not FHIR' do
      dataset = described_class.from_contents([patient_json, non_fhir_json, observation_json])

      expect(dataset.map(&:resourceType)).to eq(['Patient', 'Observation'])
      expect(dataset.map(&:id)).to eq(['patient-1', 'observation-1'])
    end

    it 'returns an empty dataset when given no contents' do
      expect(described_class.from_contents([])).to eq([])
    end
  end

  describe '.from_path' do
    it 'loads the json files in the directory and skips ones that are not FHIR' do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'patient.json'), patient_json)
        File.write(File.join(dir, 'observation.json'), observation_json)
        File.write(File.join(dir, 'not_fhir.json'), non_fhir_json)
        File.write(File.join(dir, 'ignored.txt'), patient_json)

        dataset = described_class.from_path(dir)

        expect(dataset.map(&:id)).to contain_exactly('patient-1', 'observation-1')
      end
    end
  end
end
