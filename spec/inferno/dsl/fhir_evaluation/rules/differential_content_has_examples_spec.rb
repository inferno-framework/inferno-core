# frozen_string_literal: true

require_relative '../../../../../lib/inferno/dsl/fhir_evaluation/evaluation_context'

def fixture(file)
  path = File.expand_path("../../../../../spec/fixtures/#{file}", __dir__)
  FHIR::Json.from_json(File.read(path))
end

RSpec.describe Inferno::DSL::FHIREvaluation::Rules::DifferentialContentHasExamples do
  let(:patient85) do
    fixture('patient_85.json')
  end

  it 'collects differential content on a profile' do
    profiles_to_load = [
      'StructureDefinition-us-core-medication.json'
    ]
    profiles = profiles_to_load.map { |e| fixture("#{e}") }
    # https://hl7.org/fhir/us/core/STU3.1.1/StructureDefinition-us-core-medication.html
    expected_differential = { 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-medication' => ['code'] }

    differential = Hash.new { |h, k| h[k] = Set.new }
    described_class.new.collect_profile_differential_content(differential, profiles)

    expect(differential).to include(expected_differential)
  end

  it 'collects differential content on an extension' do
    extensions_to_load = [
      'StructureDefinition-us-core-race.json'
    ]
    extensions = extensions_to_load.map { |e| fixture("#{e}") }
    # https://hl7.org/fhir/us/core/STU3.1.1/StructureDefinition-us-core-race.html
    expected_differential = { 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race' => ['extension', 'extension.url', 'extension.valueCoding', 'extension.valueString', 'url'] }

    differential = Hash.new { |h, k| h[k] = Set.new }
    described_class.new.collect_profile_differential_content(differential, extensions)

    expect(differential).to include(expected_differential)
  end

  it 'identifies used differential content' do
    profiles_to_load = [
      'StructureDefinition-us-core-patient.json'
    ]
    profiles = profiles_to_load.map { |e| fixture("#{e}") }
    ig = instance_double(Inferno::Entities::IG, profiles:, extensions: [])
    data = [patient85.entry[0].resource]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data, nil, Inferno::DSL::FHIREvaluation::Config.new)

    result = described_class.new.check(context)[0]

    # expect(result.severity).to eq('success')
    expect(result.message).to eq('All differential fields are represented in instances')
  end

  it 'identifies unused differential content' do
    profiles_to_load = [
      'StructureDefinition-us-core-medication.json'
    ]
    profiles = profiles_to_load.map { |e| fixture("#{e}") }
    # https://hl7.org/fhir/us/core/STU3.1.1/StructureDefinition-us-core-medication.html
    ig = instance_double(Inferno::Entities::IG, profiles:, extensions: [])
    data = [FHIR::Medication.new]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data, nil, Inferno::DSL::FHIREvaluation::Config.new)

    result = described_class.new.check(context)[0]

    expect(result.message).to eq("Found fields highlighted in the differential view, but not used in instances: \n Profile/Extension: http://hl7.org/fhir/us/core/StructureDefinition/us-core-medication  \n\tFields: code")
  end
end
