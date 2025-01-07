# frozen_string_literal: true

# require_relative '../../../../lib/inferno/dsl/fhir_evaluation/rules/all_resources_reachable'

RSpec.describe Inferno::DSL::FHIREvaluation::Rules::AllResourcesReachable do
  let(:patient85) do
    path = File.expand_path('patient_85.json', __dir__)
    FHIR::Json.from_json(File.read(path))
  end

  it 'identifies reachable resources by simple id' do
    patient = FHIR::Patient.new(id: '1234')
    encounter = FHIR::Encounter.new(id: 'enc999', subject: { reference: 'Patient/1234' })
    data = [patient, encounter]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(nil, data, Inferno::DSL::FHIREvaluation::Config.new)

    result = described_class.new.check(context)[0]

    expect(result.message).to eq('All resources are reachable')
  end

  it 'identifies reachable resources by uuid' do
    patient = FHIR::Patient.new(id: 'd98cdf32-2b85-450c-8e52-7dec9a390b3d')
    encounter = FHIR::Encounter.new(id: 'enc456',
                                    subject: { reference: 'urn:uuid:d98cdf32-2b85-450c-8e52-7dec9a390b3d' })
    data = [patient, encounter]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(nil, data, Inferno::DSL::FHIREvaluation::Config.new)

    result = described_class.new.check(context)[0]

    expect(result.message).to eq('All resources are reachable')
  end

  it 'identifies reachable resources with a full example' do
    data = patient85.entry.map(&:resource)
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(nil, data, Inferno::DSL::FHIREvaluation::Config.new)

    result = described_class.new.check(context)[0]

    expect(result.message).to eq('All resources are reachable')
  end

  it 'identifies unreachable resources' do
    data = [patient85.entry[0].resource] # pick just the Patient resource, which has no outgoing references
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(nil, data, Inferno::DSL::FHIREvaluation::Config.new)

    result = described_class.new.check(context)[0]

    expect(result.severity).to eq('warning')
    expect(result.message).to(
      eq("Found resources that have no resolved references and are not referenced: Patient/#{data[0].id}")
    )
  end
end
