# frozen_string_literal: true

require_relative '../../../../../lib/inferno/dsl/fhir_evaluation/evaluator'
require_relative '../../../../../lib/inferno/dsl/fhir_evaluation/evaluation_context'

def fixture(file)
  path = File.expand_path("../../../../../spec/fixtures/#{file}", __dir__)
  FHIR::Json.from_json(File.read(path))
end

RSpec.describe Inferno::DSL::FHIREvaluation::Rules::AllProfilesHaveExamples do
  let(:patient85) do
    fixture('patient_85.json')
  end

  it 'can recognize profiles used by meta.profile' do
    profiles_to_load = [
      'StructureDefinition-us-core-patient.json',
      'StructureDefinition-us-core-encounter.json'
    ]
    profiles = profiles_to_load.map { |e| fixture(e.to_s) }
    ig = instance_double(Inferno::Entities::IG, profiles:)
    data = [patient85]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data, Inferno::DSL::FHIREvaluation::Config.new,
                                                                  nil)

    result = described_class.new.check(context)[0]

    expect(result.message).to eq('All profiles have example instances.')
  end

  it 'can recognize unused profiles by meta.profile' do
    profiles_to_load = [
      'StructureDefinition-us-core-practitioner.json'
    ]
    profiles = profiles_to_load.map { |e| fixture(e.to_s) }
    ig = instance_double(Inferno::Entities::IG, profiles:)
    data = [patient85]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data, Inferno::DSL::FHIREvaluation::Config.new,
                                                                  nil)

    result = described_class.new.check(context)[0]

    expect(result.message).to eq("Found profiles without examples: \n\t http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitioner")
  end
end
