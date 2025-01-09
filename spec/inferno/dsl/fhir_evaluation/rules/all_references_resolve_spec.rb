# frozen_string_literal: true

# require_relative '../../../../lib/inferno/dsl/fhir_evaluation/rules/all_references_resolve'

RSpec.describe Inferno::DSL::FHIREvaluation::Rules::AllReferencesResolve do
  it 'identifies good references by simple id' do
    patient = FHIR::Patient.new(id: '1234')
    encounter = FHIR::Encounter.new(id: 'enc999', subject: { reference: 'Patient/1234' })
    data = [patient, encounter]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(nil, data, Inferno::DSL::FHIREvaluation::Config.new)

    result = described_class.new.check(context)[0]

    expect(result.message).to eq('All references resolve')
  end

  it 'identifies good references by uuid' do
    patient = FHIR::Patient.new(id: 'f340b51a-a70a-4971-bd45-d07fce7b935a')
    encounter = FHIR::Encounter.new(id: 'enc444',
                                    subject: { reference: 'urn:uuid:f340b51a-a70a-4971-bd45-d07fce7b935a' })
    data = [patient, encounter]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(nil, data, Inferno::DSL::FHIREvaluation::Config.new)

    result = described_class.new.check(context)[0]

    expect(result.message).to eq('All references resolve')
  end

  it 'identifies unresolvable references by simple id' do
    patient = FHIR::Patient.new(id: 'patient2')
    encounter = FHIR::Encounter.new(id: 'enc0', subject: { reference: 'wrongid' })
    data = [patient, encounter]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(nil, data, Inferno::DSL::FHIREvaluation::Config.new)

    result = described_class.new.check(context)[0]
    msg = 'Found unresolved references'

    expect(result.message).to eq("#{msg}: \n Resource (id): enc0  \n\tpath: subject, type: , id: wrongid")
  end

  it 'identifies unresolvable references by uuid' do
    patient = FHIR::Patient.new(id: 'f340b51a-a70a-4971-bd45-d07fce7b9aaa')
    encounter = FHIR::Encounter.new(id: 'enc444',
                                    subject: { reference: 'urn:uuid:aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' })
    data = [patient, encounter]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(nil, data, Inferno::DSL::FHIREvaluation::Config.new)

    result = described_class.new.check(context)[0]
    id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
    msg = 'Found unresolved references'
    expect(result.message).to eq("#{msg}: \n Resource (id): enc444  \n\tpath: subject, type: , id: #{id}")
  end
end
