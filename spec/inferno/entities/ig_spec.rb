require 'extract_tgz_helper'

RSpec.describe Inferno::Entities::IG do
  include ExtractTGZHelper

  let(:uscore3_package) { File.expand_path('../../fixtures/uscore311.tgz', __dir__) }
  let(:uscore3_untarred) { extract_tgz(uscore3_package) }

  after { cleanup(uscore3_untarred) }

  describe '#from_file' do
    it 'loads an IG from tgz file' do
      ig = described_class.from_file(uscore3_package)
      expect_uscore3_loaded_properly(ig)
    end

    it 'loads an IG from directory' do
      ig = described_class.from_file(uscore3_untarred)
      expect_uscore3_loaded_properly(ig)
    end

    def expect_uscore3_loaded_properly(ig) # rubocop:disable Naming/MethodParameterName, Metrics/CyclomaticComplexity
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
      value_sets = ig.resources_by_type['ValueSet']
      expect(value_sets.length).to eq(32)
      expect(value_sets.map(&:resourceType).uniq).to eq(['ValueSet'])
      expect(value_sets.map(&:id)).to include('us-core-usps-state', 'simple-language')

      # https://www.hl7.org/fhir/us/core/STU3.1.1/searchparameters.html
      search_params = ig.resources_by_type['SearchParameter']
      expect(search_params.length).to eq(74)
      expect(search_params.map(&:resourceType).uniq).to eq(['SearchParameter'])
      expect(search_params.map(&:id)).to include('us-core-patient-name', 'us-core-encounter-id')

      # https://www.hl7.org/fhir/us/core/STU3.1.1/all-examples.html
      expect(ig.examples.length).to eq(84)
      expect(ig.examples.map(&:id)).to include('child-example', 'self-tylenol')
    end
  end
end
