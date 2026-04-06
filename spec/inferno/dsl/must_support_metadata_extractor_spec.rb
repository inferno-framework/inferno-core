require_relative '../../extract_tgz_helper'
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

  describe '#must_support_extensions' do
    let(:type) do
      type = double
      allow(type).to receive(:profile).and_return(['http://example.org/StructureDefinition/example-extension|1.2.3'])
      type
    end

    it 'removes canonical version suffixes from extension urls' do
      expect(extractor.must_support_extensions).to eq(
        [
          {
            id: 'id',
            path: 'foo.extension',
            url: 'http://example.org/StructureDefinition/example-extension',
            modifier_extension: false
          }
        ]
      )
    end
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

    it 'extracts the discriminator path when the sliced type is on Bundle.entry.resource' do
      discriminator = FHIR::ElementDefinition::Slicing::Discriminator.new(type: 'type', path: '$this')
      slicing = FHIR::ElementDefinition::Slicing.new(discriminator: [discriminator])

      backbone_type = instance_double(FHIR::ElementDefinition::Type, code: 'BackboneElement')
      claim_type = instance_double(FHIR::ElementDefinition::Type, code: 'Claim')
      bundle_profile = instance_double(
        FHIR::StructureDefinition,
        baseDefinition: 'baseDefinition',
        name: 'bundle',
        type: 'Bundle',
        version: '2.2.0'
      )
      profile_elements = [
        instance_double(
          FHIR::ElementDefinition,
          id: 'Bundle.entry',
          path: 'Bundle.entry',
          sliceName: nil,
          mustSupport: false,
          slicing:,
          type: [backbone_type]
        ),
        instance_double(
          FHIR::ElementDefinition,
          id: 'Bundle.entry:Claim',
          path: 'Bundle.entry',
          sliceName: 'Claim',
          mustSupport: true,
          slicing: nil,
          type: [backbone_type]
        ),
        instance_double(
          FHIR::ElementDefinition,
          id: 'Bundle.entry:Claim.resource',
          path: 'Bundle.entry.resource',
          sliceName: nil,
          mustSupport: false,
          slicing: nil,
          type: [claim_type]
        )
      ]

      slices = described_class.new(profile_elements, bundle_profile, 'Bundle', ig_resources).type_slices

      expect(slices).to contain_exactly(
        {
          slice_id: 'Bundle.entry:Claim',
          slice_name: 'Claim',
          path: 'entry',
          discriminator: {
            type: 'type',
            code: 'Claim',
            path: 'resource'
          }
        }
      )
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
      # PulseOximetry profile has 2 slices by value, 1 on category, 1 on code.coding
      # and 2 slices by pattern on component.

      expect(slices.length).to eq(4)
      expect(slices[0][:slice_id]).to eq('Observation.category:VSCat')
      expect(slices[0][:path]).to eq('category')
      expect(slices[0][:discriminator][:type]).to eq('value')
      expect(slices[0][:discriminator][:values][0]).to eq({ path: 'coding.code', value: 'vital-signs' })

      expect(slices[1][:slice_id]).to eq('Observation.code.coding:PulseOx')
      expect(slices[1][:path]).to eq('code.coding')
      expect(slices[1][:discriminator][:type]).to eq('value')
      expect(slices[1][:discriminator][:values][0]).to eq({ path: 'code', value: '59408-5' })

      expect(slices[2][:slice_id]).to eq('Observation.component:FlowRate')
      expect(slices[2][:path]).to eq('component')
      expect(slices[2][:discriminator][:type]).to eq('patternCodeableConcept')
      expect(slices[2][:discriminator][:code]).to eq('3151-8')

      expect(slices[3][:slice_id]).to eq('Observation.component:Concentration')
      expect(slices[3][:path]).to eq('component')
      expect(slices[3][:discriminator][:type]).to eq('patternCodeableConcept')
      expect(slices[3][:discriminator][:code]).to eq('3150-0')
    end

    it 'extracts slices needed to navigate must support descendants' do
      discriminator = FHIR::ElementDefinition::Slicing::Discriminator.new(type: 'value', path: 'category')
      slicing = FHIR::ElementDefinition::Slicing.new(discriminator: [discriminator])
      profile_elements = [
        FHIR::ElementDefinition.new(
          id: 'Claim.supportingInfo',
          path: 'Claim.supportingInfo',
          mustSupport: false,
          slicing:
        ),
        FHIR::ElementDefinition.new(
          id: 'Claim.supportingInfo:PatientEvent',
          path: 'Claim.supportingInfo',
          sliceName: 'PatientEvent',
          mustSupport: false
        ),
        FHIR::ElementDefinition.new(
          id: 'Claim.supportingInfo:PatientEvent.category',
          path: 'Claim.supportingInfo.category',
          patternCodeableConcept: FHIR::CodeableConcept.new(
            coding: [FHIR::Coding.new(system: 'http://example.org/system', code: 'patientEvent')]
          )
        ),
        FHIR::ElementDefinition.new(
          id: 'Claim.supportingInfo:PatientEvent.timing[x]',
          path: 'Claim.supportingInfo.timing[x]',
          mustSupport: true
        )
      ]
      claim_profile = instance_double(
        FHIR::StructureDefinition,
        baseDefinition: 'baseDefinition',
        name: 'claim',
        type: 'Claim',
        version: '2.2.0'
      )

      slices = described_class.new(profile_elements, claim_profile, 'Claim', ig_resources).must_supports[:slices]

      expect(slices).to contain_exactly(
        {
          slice_id: 'Claim.supportingInfo:PatientEvent',
          slice_name: 'PatientEvent',
          path: 'supportingInfo',
          discriminator: {
            type: 'patternCodeableConcept',
            path: 'category',
            code: 'patientEvent',
            system: 'http://example.org/system'
          }
        }
      )
    end

    it 'preserves fixed false discriminator values and normalizes discriminator paths' do
      extension_url = 'http://example.org/StructureDefinition/careTeamClaimScope'
      discriminator = FHIR::ElementDefinition::Slicing::Discriminator.new(
        type: 'value',
        path: "extension('#{extension_url}').value.ofType(boolean)"
      )
      slicing = FHIR::ElementDefinition::Slicing.new(discriminator: [discriminator])
      extension_type = FHIR::ElementDefinition::Type.new(code: 'Extension', profile: [extension_url])
      boolean_type = FHIR::ElementDefinition::Type.new(code: 'boolean')
      profile_elements = [
        FHIR::ElementDefinition.new(
          id: 'Claim.careTeam',
          path: 'Claim.careTeam',
          mustSupport: false,
          slicing:
        ),
        FHIR::ElementDefinition.new(
          id: 'Claim.careTeam:ItemClaimMember',
          path: 'Claim.careTeam',
          sliceName: 'ItemClaimMember',
          mustSupport: true
        ),
        FHIR::ElementDefinition.new(
          id: 'Claim.careTeam:ItemClaimMember.extension:careTeamClaimScope',
          path: 'Claim.careTeam.extension',
          sliceName: 'careTeamClaimScope',
          type: [extension_type]
        ),
        FHIR::ElementDefinition.new(
          id: 'Claim.careTeam:ItemClaimMember.extension:careTeamClaimScope.value[x]',
          path: 'Claim.careTeam.extension.value[x]',
          type: [boolean_type],
          fixedBoolean: false
        )
      ]
      claim_profile = instance_double(
        FHIR::StructureDefinition,
        baseDefinition: 'baseDefinition',
        name: 'claim',
        type: 'Claim',
        version: '2.2.0'
      )

      slices = described_class.new(profile_elements, claim_profile, 'Claim', ig_resources).value_slices

      expect(slices).to contain_exactly(
        {
          slice_id: 'Claim.careTeam:ItemClaimMember',
          slice_name: 'ItemClaimMember',
          path: 'careTeam',
          discriminator: {
            type: 'value',
            values: [
              {
                path: "extension.where(url='#{extension_url}').valueBoolean",
                value: false
              }
            ]
          }
        }
      )
    end

    it 'normalizes legacy choice discriminator syntax using "value as boolean"' do
      extension_url = 'http://example.org/StructureDefinition/careTeamClaimScope'
      discriminator = FHIR::ElementDefinition::Slicing::Discriminator.new(
        type: 'value',
        path: "extension('#{extension_url}').value as boolean"
      )
      slicing = FHIR::ElementDefinition::Slicing.new(discriminator: [discriminator])
      extension_type = FHIR::ElementDefinition::Type.new(code: 'Extension', profile: [extension_url])
      boolean_type = FHIR::ElementDefinition::Type.new(code: 'boolean')
      profile_elements = [
        FHIR::ElementDefinition.new(
          id: 'Claim.careTeam',
          path: 'Claim.careTeam',
          mustSupport: false,
          slicing:
        ),
        FHIR::ElementDefinition.new(
          id: 'Claim.careTeam:OverallClaimMember',
          path: 'Claim.careTeam',
          sliceName: 'OverallClaimMember',
          mustSupport: true
        ),
        FHIR::ElementDefinition.new(
          id: 'Claim.careTeam:OverallClaimMember.extension:careTeamClaimScope',
          path: 'Claim.careTeam.extension',
          sliceName: 'careTeamClaimScope',
          type: [extension_type]
        ),
        FHIR::ElementDefinition.new(
          id: 'Claim.careTeam:OverallClaimMember.extension:careTeamClaimScope.value[x]',
          path: 'Claim.careTeam.extension.value[x]',
          type: [boolean_type],
          fixedBoolean: true
        )
      ]
      claim_profile = instance_double(
        FHIR::StructureDefinition,
        baseDefinition: 'baseDefinition',
        name: 'claim',
        type: 'Claim',
        version: '2.0.1'
      )

      slices = described_class.new(profile_elements, claim_profile, 'Claim', ig_resources).value_slices

      expect(slices).to contain_exactly(
        {
          slice_id: 'Claim.careTeam:OverallClaimMember',
          slice_name: 'OverallClaimMember',
          path: 'careTeam',
          discriminator: {
            type: 'value',
            values: [
              {
                path: "extension.where(url='#{extension_url}').valueBoolean",
                value: true
              }
            ]
          }
        }
      )
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
