require_relative '../../../lib/inferno/dsl/value_extractor'
require 'extract_tgz_helper'

RSpec.describe Inferno::DSL::ValueExtractor do
  include ExtractTGZHelper

  let(:uscore3_package) { File.expand_path('../../fixtures/uscore311.tgz', __dir__) }
  let(:uscore3_untarred) { extract_tgz(uscore3_package) }
  let(:uscore3_ig) { Inferno::Entities::IG.from_file(uscore3_untarred) }

  def fixture(filename)
    path = File.join(uscore3_untarred, 'package', filename)
    FHIR::Json.from_json(File.read(path))
  end

  after { cleanup(uscore3_untarred) }

  describe '#values_from_fixed_codes' do
    let(:bmi_for_age_profile) { fixture('StructureDefinition-pediatric-bmi-for-age.json') }

    it 'extracts codes from an element with fixedCode' do
      elements = bmi_for_age_profile.snapshot.element
      extractor = described_class.new(nil, bmi_for_age_profile.type, elements)
      # https://www.hl7.org/fhir/us/core/STU3.1.1/StructureDefinition-pediatric-bmi-for-age.html
      # category.coding.code is fixed to "vital-signs"

      category_element = elements.find { |e| e.path == 'Observation.category' }

      expect(extractor.values_from_fixed_codes(category_element, 'CodeableConcept')).to contain_exactly('vital-signs')
    end
  end

  describe '#values_from_pattern_coding' do
    let(:pulse_ox_profile) do
      # unfortunately there are no profiles in US Core 3 with a patternCoding
      # so this one comes from US Core 4
      FHIR.from_contents(File.read('spec/fixtures/StructureDefinition-us-core-pulse-oximetry_v400.json'))
    end

    it 'extracts codes from an element with patternCoding' do
      elements = pulse_ox_profile.snapshot.element
      extractor = described_class.new(nil, pulse_ox_profile.type, elements)
      # https://hl7.org/fhir/us/core/STU4/StructureDefinition-us-core-pulse-oximetry.html
      # Observation.code has 2 slices:
      # PulseOx: {system: "http://loinc.org", code: "59408-5"}
      # O2Sat:   {system: "http://loinc.org", code: "2708-6"}
      code_element = elements.find { |e| e.path == 'Observation.code' }

      expect(extractor.values_from_pattern_coding(code_element,
                                                  'CodeableConcept')).to contain_exactly('59408-5', '2708-6')
    end
  end

  describe '#values_from_pattern_codeable_concept' do
    let(:observation_lab_profile) { fixture('StructureDefinition-us-core-observation-lab.json') }

    it 'extracts codes from an element with patternCodeableConcept' do
      elements = observation_lab_profile.snapshot.element
      extractor = described_class.new(nil, observation_lab_profile.type, elements)
      # https://www.hl7.org/fhir/us/core/STU3.1.1/StructureDefinition-us-core-observation-lab.html

      category_element = elements.find { |e| e.path == 'Observation.category' }

      expect(extractor.values_from_pattern_codeable_concept(category_element,
                                                            'CodeableConcept')).to contain_exactly('laboratory')
    end
  end

  describe '#bound_systems' do
    let(:smoking_status_profile) do
      uscore3_ig.profile_by_url('http://hl7.org/fhir/us/core/StructureDefinition/us-core-smokingstatus')
    end
    let(:smoking_status_vs) do
      uscore3_ig.value_set_by_url('http://hl7.org/fhir/us/core/ValueSet/us-core-smoking-status-observation-codes')
    end
    let(:condition_profile) do
      uscore3_ig.profile_by_url('http://hl7.org/fhir/us/core/StructureDefinition/us-core-condition')
    end
    let(:condition_category_vs) do
      uscore3_ig.value_set_by_url('http://hl7.org/fhir/us/core/ValueSet/us-core-condition-category')
    end

    let(:condition_category_code_system) do
      FHIR::CodeSystem.new(
        {
          resourceType: 'CodeSystem',
          id: 'condition-category',
          url: 'http://terminology.hl7.org/CodeSystem/condition-category',
          identifier: [
            {
              system: 'urn:ietf:rfc:3986',
              value: 'urn:oid:2.16.840.1.113883.4.642.1.1073'
            }
          ],
          version: '0.5.0',
          name: 'ConditionCategoryCodes',
          title: 'Condition Category Codes',
          description: 'Preferred value set for Condition Categories.',
          caseSensitive: true,
          valueSet: 'http://terminology.hl7.org/ValueSet/condition-category',
          content: 'complete',
          concept: [
            {
              code: 'problem-list-item',
              display: 'Problem List Item',
              definition: 'An item on a problem list that can be managed over time[...]'
            },
            {
              code: 'encounter-diagnosis',
              display: 'Encounter Diagnosis',
              definition: 'A point in time diagnosis (e.g. from a physician or nurse) in context of an encounter.'
            }
          ]
        }
      )
    end

    it 'gets systems for VS with include.concept' do
      # ValueSet-us-core-smoking-status-observation-codes.json
      elements = smoking_status_profile.snapshot.element
      extractor = described_class.new(uscore3_ig, smoking_status_profile.type, elements)

      code_field = elements.find { |e| e.path == 'Observation.code' }

      result = extractor.bound_systems(code_field)

      expect(result[0]).to be_a(FHIR::R4::ValueSet::Compose::Include)
      expect(result[0].system).to eq('http://loinc.org')
      expect(result[0].concept[0].code).to eq('72166-2')
    end

    it 'gets systems for VS with include.system without concept or filter' do
      # ValueSet-us-core-condition-category.json
      elements = condition_profile.snapshot.element
      extractor = described_class.new(uscore3_ig, condition_profile.type, elements)

      # NOTE: we cheat here, this VS references codesystem:
      # http://terminology.hl7.org/CodeSystem/condition-category
      # which is a core FHIR codesystem, not part of the IG.
      # for this test we add it to the IG so the local lookup works
      uscore3_ig.handle_resource(condition_category_code_system, '')

      category_field = elements.find { |e| e.path == 'Condition.category' }
      result = extractor.bound_systems(category_field)

      expect(result[0]).to be_a(FHIR::CodeSystem)
      expect(result[0].url).to eq('http://terminology.hl7.org/CodeSystem/condition-category')
    end
  end

  describe '#codes_from_value_set_binding' do
    let(:smoking_status_profile) do
      uscore3_ig.profile_by_url('http://hl7.org/fhir/us/core/StructureDefinition/us-core-smokingstatus')
    end

    it 'extracts code when the VS has bound systems' do
      elements = smoking_status_profile.snapshot.element
      extractor = described_class.new(uscore3_ig, smoking_status_profile.type, elements)
      code_field = elements.find { |e| e.path == 'Observation.code' }

      result = extractor.codes_from_value_set_binding(code_field)
      expect(result).to contain_exactly('72166-2')
    end
  end

  describe '#values_from_resource_metadata' do
    it 'extracts fixed values for a given field' do
      extractor = described_class.new(nil, 'Location', nil)
      # Location.status has just a few possible codes
      # https://hl7.org/fhir/r4/valueset-location-status.html
      field_with_valid_codes = 'status'
      field_without_valid_codes = 'name'
      paths = [field_with_valid_codes, field_without_valid_codes]
      result = extractor.values_from_resource_metadata(paths)

      sys = 'http://hl7.org/fhir/location-status'
      expected_results = [
        { system: sys, code: 'active' },
        { system: sys, code: 'suspended' },
        { system: sys, code: 'inactive' }
      ]

      expect(result).to match_array(expected_results)
    end
  end
end
