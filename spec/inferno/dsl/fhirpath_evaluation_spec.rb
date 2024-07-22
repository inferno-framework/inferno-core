require_relative '../../../lib/inferno/dsl/fhirpath_evaluation'
RSpec.describe Inferno::DSL::FhirpathEvaluation do
  
  let(:evaluator) {Inferno::DSL::FhirpathEvaluation::Evaluator.new}

  #patient example adapted from https://fhirpath-lab.azurewebsites.net/FhirPath/
  let(:patient) { FHIR::Patient.new(
    id: 'example',
    name: [FHIR::HumanName.new(family: 'Chalmers', given: ['Peter', 'James'])],
    gender: 'male',
    birthdate: '1974-12-25'
  ) }

  it 'is tests evaluating a fhirpath expression against a known patient resource' do
    birthdate_expression = 'Patient.birthdate'
    expected_birthdate = '1974-12-25'
    birthdate_result = evaluator.evaluate_fhirpath(patient, birthdate_expression)
    expect(birthdate_result).to eq(expected_birthdate)
  end
end