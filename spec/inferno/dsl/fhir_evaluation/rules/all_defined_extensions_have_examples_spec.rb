# frozen_string_literal: true

require_relative '../../../../../lib/inferno/dsl/fhir_evaluation/evaluation_context'

def fixture(file)
  path = File.expand_path("../../../../../spec/fixtures/#{file}", __dir__)
  FHIR::Json.from_json(File.read(path))
end

RSpec.describe Inferno::DSL::FHIREvaluation::Rules::AllDefinedExtensionsHaveExamples do
  let(:patient85) do
    fixture('patient_85.json')
  end

  it 'can get all extensions from resources' do
    rule = described_class.new
    expected_extension_urls = [
      'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race',
      # the function returns sub-extensions as well as "top-level" extensions
      'ombCategory',
      'text',
      'http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity',
      'http://hl7.org/fhir/StructureDefinition/patient-mothersMaidenName',
      'http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex',
      'http://hl7.org/fhir/us/core/StructureDefinition/us-core-sex',
      'http://hl7.org/fhir/StructureDefinition/patient-birthPlace',
      'http://hl7.org/fhir/us/core/StructureDefinition/us-core-genderIdentity',
      'http://hl7.org/fhir/StructureDefinition/geolocation',
      'latitude',
      'longitude'
    ]

    expect(rule.extension_urls(patient85)).to match_array(expected_extension_urls)
  end

  it 'identifies present extensions' do
    extensions_to_load = [
      'StructureDefinition-us-core-race.json',
      'StructureDefinition-us-core-ethnicity.json'
    ]
    extensions = extensions_to_load.map { |e| fixture(e.to_s) }
    ig = instance_double(Inferno::Entities::IG, extensions:)
    data = [patient85]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data, Inferno::DSL::FHIREvaluation::Config.new,
                                                                  nil)

    result = described_class.new.check(context)[0]

    expect(result.severity).to eq('success')
    expect(result.message).to eq('All defined extensions are represented in examples')
  end

  it 'identifies missing extensions' do
    extensions = [fixture('StructureDefinition-us-core-direct.json')]
    ig = instance_double(Inferno::Entities::IG, extensions:)
    data = [patient85]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data, Inferno::DSL::FHIREvaluation::Config.new,
                                                                  nil)

    result = described_class.new.check(context)[0]

    expect(result.severity).to eq('warning')
    expect(result.message).to eq("Found unused extensions defined in the IG: \n\t http://hl7.org/fhir/us/core/StructureDefinition/us-core-direct")
  end
end
