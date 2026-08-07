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

    def expect_uscore3_loaded_properly(ig) # rubocop:disable Metrics/CyclomaticComplexity
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

      patient_profile_url = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient'

      expect(ig.resource_for_profile(patient_profile_url)).to eq('Patient')

      patient_profile = ig.profile_by_url(patient_profile_url)
      expect(patient_profile.resourceType).to eq('StructureDefinition')
      expect(patient_profile.id).to eq('us-core-patient')

      condition_codes_vs = ig.value_set_by_url('http://hl7.org/fhir/us/core/ValueSet/us-core-condition-code')
      expect(condition_codes_vs.resourceType).to eq('ValueSet')
      expect(condition_codes_vs.title).to eq('US Core Condition Code')

      race_ethnicity_cs = ig.code_system_by_url('urn:oid:2.16.840.1.113883.6.238')
      expect(race_ethnicity_cs.resourceType).to eq('CodeSystem')
      expect(race_ethnicity_cs.title).to eq('Race & Ethnicity - CDC')
    end

    context 'with standalone_resources_directory' do
      let(:standalone_resources_dir) { Dir.mktmpdir('standalone_resources') }

      after { FileUtils.remove_entry(standalone_resources_dir) }

      def write_standalone_resource(dir, file_name, resource)
        File.write(File.join(dir, file_name), resource.to_json)
      end

      it 'merges in loose FHIR resource files from the given directory' do
        write_standalone_resource(
          standalone_resources_dir, 'extra-patient.json', FHIR::Patient.new(id: 'extra-patient')
        )

        ig = described_class.from_file(uscore3_package, standalone_resources_directory: standalone_resources_dir)

        expect(ig.resources_by_type['Patient'].map(&:id)).to include('extra-patient')
      end

      it 'skips files that are not valid FHIR resources' do
        File.write(File.join(standalone_resources_dir, 'not-fhir.json'), '{"not": "a fhir resource"}')

        expect do
          described_class.from_file(uscore3_package, standalone_resources_directory: standalone_resources_dir)
        end.to_not raise_error
      end

      it 'does nothing when no directory is given' do
        ig = described_class.from_file(uscore3_package)

        expect_uscore3_loaded_properly(ig)
      end

      it 'does nothing when the given directory does not exist' do
        ig = described_class.from_file(uscore3_package, standalone_resources_directory: '/no/such/directory')

        expect_uscore3_loaded_properly(ig)
      end
    end
  end

  describe '#merge_standalone_resources' do
    let(:standalone_resources_dir) { Dir.mktmpdir('standalone_resources') }

    after { FileUtils.remove_entry(standalone_resources_dir) }

    it 'returns self' do
      ig = described_class.from_file(uscore3_package)

      expect(ig.merge_standalone_resources(standalone_resources_dir)).to eq(ig)
    end

    it 'adds resources to resources_by_type rather than examples' do
      File.write(
        File.join(standalone_resources_dir, 'extra-observation.json'),
        FHIR::Observation.new(id: 'extra-observation').to_json
      )

      ig = described_class.from_file(uscore3_package)
      ig.merge_standalone_resources(standalone_resources_dir)

      expect(ig.resources_by_type['Observation'].map(&:id)).to include('extra-observation')
      expect(ig.examples.map(&:id)).to_not include('extra-observation')
    end
  end
end
