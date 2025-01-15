require_relative '../../../lib/inferno/dsl/must_support_metadata_extractor'

RSpec.describe Inferno::DSL::MustSupportMetadataExtractor do
  include ExtractTGZHelper

  let(:uscore3_package) { File.expand_path('../../fixtures/uscore311.tgz', __dir__) }
  let(:uscore3_ig) { Inferno::Entities::IG.from_file(uscore3_package) }

  let(:extractor) { described_class.new([profile_element], profile, 'resourceConstructor', ig_resources) }

  let(:profile) do
    profile = double
    allow(profile).to receive_messages(baseDefinition: 'baseDefinition', name: 'name', type: 'type', version: 'version')
    profile
  end
  let(:ig_resources) do
    ig_resources = double
    allow(ig_resources).to receive(:value_set_by_url).and_return(nil)
    ig_resources
  end

  let(:type) do
    type = double
    allow(type).to receive(:profile).and_return(['profile_url'])
    type
  end

  let(:profile_element) { double }

  before do
    allow(profile_element).to receive_messages(mustSupport: true, path: 'foo.extension', id: 'id', type: [type])
  end

  describe '#get_type_must_support_metadata' do
    let(:metadata) do
      { path: 'path' }
    end

    let(:type) do
      type = double
      allow(type).to receive_messages(extension: 'extension', code: 'code')
      type
    end

    let(:element) do
      element = double
      allow(element).to receive(:type).and_return([type])
      element
    end

    it 'returns a path and an original path when type_must_support_extension' do
      allow(extractor).to receive(:type_must_support_extension?).and_return(true)

      result = extractor.get_type_must_support_metadata(metadata, element)

      expected = [{ original_path: 'path', path: 'pathCode' }]
      expect(result).to eq(expected)
    end

    it 'returns empty when not type_must_support_extension' do
      allow(extractor).to receive(:type_must_support_extension?).and_return(false)

      result = extractor.get_type_must_support_metadata(metadata, element)

      expected = []
      expect(result).to eq(expected)
    end
  end

  describe '#type_slices' do
    let(:goal_profile) { uscore3_ig.profile_by_url('http://hl7.org/fhir/us/core/StructureDefinition/us-core-goal') }
    let(:goal_extractor) do
      described_class.new(goal_profile.snapshot.element, goal_profile, goal_profile.type, uscore3_ig)
    end

    it 'extracts slices from profile with slicing by type' do
      slices = goal_extractor.type_slices

      # Goal profile has a slice on target.due[x], fixed to type date (ie, dueDate)
      # rubocop:disable Layout/LineLength
      # https://www.hl7.org/fhir/us/core/STU3.1.1/StructureDefinition-us-core-goal-definitions.html#Goal.target.due[x]:dueDate
      # rubocop:enable Layout/LineLength

      expect(slices.length).to be(1)
      expect(slices[0][:slice_id]).to eq('Goal.target.due[x]:dueDate')
      expect(slices[0][:path]).to eq('target.due[x]')
      expect(slices[0][:discriminator][:type]).to eq('type')
      expect(slices[0][:discriminator][:code]).to eq('Date')
    end
  end

  describe '#value_slices' do
    let(:pulseox_profile) { uscore3_ig.profile_by_url('http://hl7.org/fhir/us/core/StructureDefinition/us-core-pulse-oximetry') }
    let(:pulseox_extractor) do
      described_class.new(pulseox_profile.snapshot.element, pulseox_profile, pulseox_profile.type, uscore3_ig)
    end

    it 'extracts slices from profile with slicing by value' do
      slices = pulseox_extractor.value_slices

      # https://www.hl7.org/fhir/us/core/STU3.1.1/StructureDefinition-us-core-pulse-oximetry.html
      # PulseOximetry profile has 2 slices by value:
      # 1 on category, 1 on code.coding

      expect(slices.length).to be(2)
      expect(slices[0][:slice_id]).to eq('Observation.category:VSCat')
      expect(slices[0][:path]).to eq('category')
      expect(slices[0][:discriminator][:type]).to eq('value')
      expect(slices[0][:discriminator][:values][0]).to eq({ path: 'coding.code', value: 'vital-signs' })

      expect(slices[1][:slice_id]).to eq('Observation.code.coding:PulseOx')
      expect(slices[1][:path]).to eq('code.coding')
      expect(slices[1][:discriminator][:type]).to eq('value')
      expect(slices[1][:discriminator][:values][0]).to eq({ path: 'code', value: '59408-5' })
    end
  end

  describe '#must_support_elements' do
    let(:ped_weight_for_height_profile) do
      uscore3_ig.profile_by_url('http://hl7.org/fhir/us/core/StructureDefinition/pediatric-weight-for-height')
    end

    it 'extracts the expected MS elements' do
      pwh_extractor = described_class.new(ped_weight_for_height_profile.snapshot.element,
                                          ped_weight_for_height_profile, ped_weight_for_height_profile.type, uscore3_ig)

      ms_elements = pwh_extractor.must_support_elements
      # https://www.hl7.org/fhir/us/core/STU3.1.1/StructureDefinition-pediatric-weight-for-height.html#profile
      # note also the inhereted elements from the core vital-signs profile
      # http://hl7.org/fhir/R4/vitalsigns.html

      expect(ms_elements).to include(
        { path: 'category' },
        { path: 'category:VSCat.coding' },
        { path: 'category:VSCat.coding.code', fixed_value: 'vital-signs' },
        { path: 'category:VSCat.coding.system',
          fixed_value: 'http://terminology.hl7.org/CodeSystem/observation-category' },
        { path: 'code.coding.code', fixed_value: '77606-2' },
        { path: 'subject', types: ['Reference'],
          target_profiles: ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient'] },
        { path: 'value[x]' },
        { path: 'value[x]:valueQuantity.value' },
        { path: 'value[x]:valueQuantity.unit' },
        { path: 'value[x]:valueQuantity.system', fixed_value: 'http://unitsofmeasure.org' },
        { path: 'value[x]:valueQuantity.code', fixed_value: '%' }
      )
    end
  end

  describe '#by_requirement_extension_only?' do
    let(:dr_profile) do
      # unfortunately there are no profiles in US Core 3 with a uscdi-requirement extension
      # so this one comes from US Core 6.1.0
      FHIR.from_contents(File.read('spec/fixtures/StructureDefinition-us-core-documentreference_v610.json'))
    end

    let(:dr_category_slice_element) do
      dr_profile.snapshot.element.find { |e| e.id == 'DocumentReference.category:uscore' }
    end

    it 'identifies uscdi elements when provided the uscdi extension url' do
      extension_url = 'http://hl7.org/fhir/us/core/StructureDefinition/uscdi-requirement'
      dr_extractor = described_class.new(dr_profile.snapshot.element, dr_profile, dr_profile.type, uscore3_ig,
                                         extension_url)

      expect(dr_extractor).to be_by_requirement_extension_only(dr_category_slice_element)
    end

    it 'ignores uscdi elements when provided no requirement extension' do
      dr_extractor = described_class.new(dr_profile.snapshot.element, dr_profile, dr_profile.type, uscore3_ig)

      expect(dr_extractor).to_not be_by_requirement_extension_only(dr_category_slice_element)
    end

    it 'ignores uscdi elements when provided a different requirement extension' do
      extension_url = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-interpreter-needed'
      dr_extractor = described_class.new(dr_profile.snapshot.element, dr_profile, dr_profile.type, uscore3_ig,
                                         extension_url)

      expect(dr_extractor).to_not be_by_requirement_extension_only(dr_category_slice_element)
    end
  end
end
