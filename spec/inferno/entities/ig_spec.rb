RSpec.describe Inferno::Entities::IG do
  let(:uscore3_package) { File.expand_path('../../fixtures/uscore311.tgz', __dir__) }

  describe '#from_file' do
    it 'loads an IG from file' do
      ig = described_class.from_file(uscore3_package)

      # For each artifact type in the IG, check:
      # the right number are loaded,
      # they're all the expected type,
      # and spot check a couple IDs

      # https://www.hl7.org/fhir/us/core/STU3.1.1/profiles.html
      expect(ig.profiles.length).to eq(26)
      expect(ig.profiles.map(&:resourceType).uniq).to eq(['StructureDefinition'])
      expect(ig.profiles.map(&:id)).to include('us-core-patient', 'us-core-condition',
                                               'head-occipital-frontal-circumference-percentile')

      expect(ig.extensions.length).to eq(4)
      expect(ig.extensions.map(&:resourceType).uniq).to eq(['StructureDefinition'])
      expect(ig.extensions.map(&:type).uniq).to eq(['Extension'])
      expect(ig.extensions.map(&:id)).to include('us-core-race', 'us-core-ethnicity')

      # https://www.hl7.org/fhir/us/core/STU3.1.1/terminology.html
      expect(ig.value_sets.length).to eq(32)
      expect(ig.value_sets.map(&:resourceType).uniq).to eq(['ValueSet'])
      expect(ig.value_sets.map(&:id)).to include('us-core-usps-state', 'simple-language')

      # https://www.hl7.org/fhir/us/core/STU3.1.1/searchparameters.html
      expect(ig.search_params.length).to eq(74)
      expect(ig.search_params.map(&:resourceType).uniq).to eq(['SearchParameter'])
      expect(ig.search_params.map(&:id)).to include('us-core-patient-name', 'us-core-encounter-id')

      # https://www.hl7.org/fhir/us/core/STU3.1.1/all-examples.html
      expect(ig.examples.length).to eq(84)
      expect(ig.examples.map(&:id)).to include('child-example', 'self-tylenol')
    end
  end
end
