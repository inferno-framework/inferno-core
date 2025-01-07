require_relative '../../../../lib/inferno/dsl/fhir_evaluation/profile_conformance_checker'

RSpec.describe Inferno::DSL::FHIREvaluation::ProfileConformanceChecker do
  let(:checker_class) do
    Class.new do
      include Inferno::DSL::FHIREvaluation::ProfileConformanceChecker
    end
  end

  let(:checker) { checker_class.new }

  let(:patient_profile) do
    FHIR::StructureDefinition.new(
      url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient',
      version: '3.1.1',
      name: 'USCorePatientProfile',
      kind: 'resource',
      abstract: false,
      type: 'Patient'
    )
  end

  let(:patient) do
    FHIR::Patient.new(
      meta: { profile: ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient'] },
      identifier: [{ system: 'system', value: 'value' }],
      name: [{ use: 'old', family: 'family', given: ['given'], suffix: ['suffix'], period: { end: '2022-12-12' } }],
      telecom: [{ system: 'phone', value: 'value', use: 'home' }],
      gender: 'male',
      birthDate: '2020-01-01',
      deceasedDateTime: '2022-12-12',
      address: [{ use: 'old', line: 'line', city: 'city', state: 'state', postalCode: 'postalCode',
                  period: { start: '2020-01-01' } }],
      communication: [{ language: { text: 'text' } }],
      extension: [
        {
          url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race',
          extension: [
            { url: 'ombCategory', valueCoding: { display: 'display' } },
            { url: 'text', valueString: 'valueString' }
          ]
        },
        {
          url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity',
          extension: [
            { url: 'ombCategory', valueCoding: { display: 'display' } },
            { url: 'text', valueString: 'valueString' }
          ]
        },
        {
          url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex',
          valueCode: 'M'
        },
        {
          url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-tribal-affiliation',
          extension: [{ url: 'tribalAffiliation', valueCodeableConcept: { text: 'text' } }]
        },
        {
          url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-sex',
          valueCode: 'M'
        },
        {
          url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-genderIdentity',
          valueCodeableConcept: { text: 'text' }
        }
      ]
    )
  end

  describe '#conforms_to_profile?' do
    it 'returns false for the wrong resource type' do
      options = {}
      observation = FHIR::Observation.new
      result = checker.conforms_to_profile?(observation, patient_profile, options)

      expect(result).to be(false)
    end

    it 'returns true for the right resource type if considerOnlyResourceType' do
      options = {
        considerMetaProfile: true,
        considerOnlyResourceType: true
      }
      patient = FHIR::Patient.new

      result = checker.conforms_to_profile?(patient, patient_profile, options)
      expect(result).to be(true)
    end

    it 'returns true for a resource declaring meta.profile if considerMetaProfile' do
      options = {
        considerMetaProfile: true,
        considerOnlyResourceType: false
      }
      result = checker.conforms_to_profile?(patient, patient_profile, options)

      expect(result).to be(true)
    end

    it 'returns true for a resource declaring versioned meta.profile if considerMetaProfile' do
      options = {
        considerMetaProfile: true,
        considerOnlyResourceType: false
      }
      patient.meta.profile[0] = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient|3.1.1'
      result = checker.conforms_to_profile?(patient, patient_profile, options)

      expect(result).to be(true)
    end

    it 'raises for Not Yet Implemented if considerValidationResults' do
      options = {
        considerMetaProfile: false,
        considerOnlyResourceType: false,
        considerValidationResults: true
      }
      validator = nil
      expect do
        checker.conforms_to_profile?(patient, patient_profile, options, validator)
      end.to raise_error(StandardError, /Profile validation is not yet implemented/)
    end
  end
end
