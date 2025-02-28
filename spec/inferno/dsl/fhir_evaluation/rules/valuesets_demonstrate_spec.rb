# frozen_string_literal: true

require_relative '../../../../../lib/inferno/dsl/fhir_evaluation/evaluation_context'

def fixture(file)
  path = File.expand_path("../../../../../spec/fixtures/#{file}", __dir__)
  FHIR::Json.from_json(File.read(path))
end

RSpec.describe Inferno::DSL::FHIREvaluation::Rules::ValueSetsDemonstrate do
  let(:patient85) do
    fixture('patient_85.json')
  end

  it 'identifies used valuesets' do
    value_sets_to_load = [
      'ValueSet-us-core-observation-smokingstatus.json'
    ]
    value_sets = value_sets_to_load.map { |e| fixture("#{e}") }
    ig = instance_double(Inferno::Entities::IG, value_sets:)
    smoking_status_obs = patient85.entry.map(&:resource).find do |r|
      r.resourceType == 'Observation' && r.code.text == 'Tobacco smoking status'
    end
    data = [smoking_status_obs]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data, nil, Inferno::DSL::FHIREvaluation::Config.new)

    result = described_class.new.check(context)[0]

    expect(result.severity).to eq('success')
    expect(result.message).to eq("All Value sets are used in Examples:\n\thttp://hl7.org/fhir/us/core/ValueSet/us-core-observation-smokingstatus is used 1 times in 1 resources")
  end

  it 'identifies unused valuesets' do
    value_sets_to_load = [
      'ValueSet-us-core-observation-smokingstatus.json'
    ]
    value_sets = value_sets_to_load.map { |e| fixture("#{e}") }
    ig = instance_double(Inferno::Entities::IG, value_sets:)
    data = [FHIR::Observation.new]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data, nil, Inferno::DSL::FHIREvaluation::Config.new)

    result = described_class.new.check(context)[0]

    expect(result.message).to eq("All codes in these value sets are used at least once in Examples:\nFound unused Value Sets: \n\thttp://hl7.org/fhir/us/core/ValueSet/us-core-observation-smokingstatus")
  end
end
