# frozen_string_literal: true

require_relative '../../../../../lib/inferno/dsl/fhir_evaluation/evaluation_context'

def fixture(file)
  path = File.expand_path("../../../../../spec/fixtures/#{file}", __dir__)
  FHIR::Json.from_json(File.read(path))
end

RSpec.describe Inferno::DSL::FHIREvaluation::Rules::AllExtensionsUsed do
  let(:patient85) do
    fixture('patient_85.json')
  end

  it 'collects extensions on a profile' do
    profiles_to_load = [
      'StructureDefinition-us-core-patient.json'
    ]
    profiles = profiles_to_load.map { |e| fixture("#{e}") }
    # https://hl7.org/fhir/us/core/STU3.1.1/StructureDefinition-us-core-patient.html
    expected_extension_urls = { 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient' =>
      [
        'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race',
        'http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity',
        'http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex'
      ] }

    found_extensions = described_class.new.collect_profile_extensions(profiles)

    expect(found_extensions).to include(expected_extension_urls)
  end

  it 'identifies used extensions' do
    profiles_to_load = [
      'StructureDefinition-us-core-patient.json'
    ]
    profiles = profiles_to_load.map { |e| fixture("#{e}") }
    ig = instance_double(Inferno::Entities::IG, profiles:)
    data = [patient85.entry[0].resource]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data, nil, Inferno::DSL::FHIREvaluation::Config.new)

    result = described_class.new.check(context)[0]

    # expect(result.severity).to eq('success')
    expect(result.message).to eq('All extensions specified in profiles are represented in instances.')
  end

  it 'identifies unused extensions' do
    profiles_to_load = [
      'StructureDefinition-us-core-patient.json'
    ]
    profiles = profiles_to_load.map { |e| fixture("#{e}") }
    ig = instance_double(Inferno::Entities::IG, profiles:)
    data = [FHIR::Patient.new(meta: { profile: ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient'] })]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data, nil, Inferno::DSL::FHIREvaluation::Config.new)

    result = described_class.new.check(context)[0]

    expect(result.message).to eq("Found extensions specified in profiles, but not used in instances:\n Profile: http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient, \n\tExtensions: http://hl7.org/fhir/us/core/StructureDefinition/us-core-race, http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity, http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex")
                                 
    data = [FHIR::Patient.new(meta: { profile: ['http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient'] },
                              extension: [{
                                url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex', valueCode: 'female'
                              }])]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data, nil, Inferno::DSL::FHIREvaluation::Config.new)
    result2 = described_class.new.check(context)[0]

    expect(result2.message).to eq("Found extensions specified in profiles, but not used in instances:\n Profile: http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient, \n\tExtensions: http://hl7.org/fhir/us/core/StructureDefinition/us-core-race, http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity")
  end
end
