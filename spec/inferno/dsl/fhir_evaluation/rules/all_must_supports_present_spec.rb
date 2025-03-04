require 'extract_tgz_helper'
require 'ostruct'

require_relative '../../../../../lib/inferno/dsl/fhir_evaluation/evaluator'

RSpec.describe Inferno::DSL::FHIREvaluation::Rules::AllMustSupportsPresent do
  include ExtractTGZHelper

  let(:uscore3_package) { File.realpath(File.join(Dir.pwd, 'spec/fixtures/uscore311.tgz')) }
  let(:patient_ref) { 'Patient/85' }
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
  let(:uscore3_untarred) { extract_tgz(uscore3_package) }

  def fixture(filename)
    path = File.join(uscore3_untarred, 'package', filename)
    FHIR::Json.from_json(File.read(path))
  end

  def metadata_fixture(filename)
    path = File.realpath(File.join(Dir.pwd, 'spec/fixtures/metadata', filename))
    metadata_yaml = YAML.load_file(path)
    OpenStruct.new(metadata_yaml) # so that the top-level keys can be accessed directly, ie metadata.must_supports[...]
  end

  after { cleanup(uscore3_untarred) }

  describe '#check' do
    it 'identifies when all MS elements are used' do
      profiles = [fixture('StructureDefinition-us-core-patient.json')]
      ig = instance_double(Inferno::Entities::IG, profiles:)
      data = [patient]
      config = Inferno::DSL::FHIREvaluation::Config.new
      validator = nil
      context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data, config, validator)

      described_class.new.check(context)
      result = context.results[0]

      expect(result.message).to eq('All MustSupports are present')
    end

    it 'identifies when no relevant resources are present' do
      profiles = [fixture('StructureDefinition-us-core-medication.json')]
      ig = instance_double(Inferno::Entities::IG, profiles:)
      data = [patient]
      config = Inferno::DSL::FHIREvaluation::Config.new
      validator = nil
      context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data, config, validator)

      described_class.new.check(context)
      result = context.results[0]

      expect(result.message).to end_with('No matching resources were found to check')
    end

    it 'identifies when not all MS elements are used' do
      profiles = [fixture('StructureDefinition-us-core-medication.json')]
      ig = instance_double(Inferno::Entities::IG, profiles:)
      empty_med = FHIR::Medication.new(
        meta: { profile: ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-medication'] }
      )
      data = [empty_med]
      config = Inferno::DSL::FHIREvaluation::Config.new
      validator = nil
      context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data, config, validator)

      described_class.new.check(context)
      result = context.results[0]

      expect(result.message).to end_with('http://hl7.org/fhir/us/core/StructureDefinition/us-core-medication: code')
    end
  end
end
