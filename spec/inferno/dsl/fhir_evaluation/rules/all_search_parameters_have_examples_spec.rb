# frozen_string_literal: true

require_relative '../../../../../lib/inferno/dsl/fhir_evaluation/evaluation_context'

RSpec.describe Inferno::DSL::FHIREvaluation::Rules::AllSearchParametersHaveExamples do
  it 'test with US Core 3.1.1 search params and example data included in the IG' do
    ig = Inferno::Entities::IG.from_file('spec/fixtures/uscore311.tgz')
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, ig.examples,
                                                                  Inferno::DSL::FHIREvaluation::Config.new, nil)
    fhirpath = "#{ENV.fetch('FHIRPATH_URL', nil)}/evaluate?path="
    stub_request(:post, "#{fhirpath}Bundle").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}AllergyIntolerance.clinicalStatus").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}AllergyIntolerance.patient").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}CarePlan.category").to_return(status: 200,
                                                                  body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}CarePlan.period").to_return(status: 200,
                                                                body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}CarePlan.subject.where(resolve() is Patient)").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}CarePlan.status").to_return(status: 200,
                                                                body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}CareTeam.subject.where(resolve() is Patient)").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}CareTeam.status").to_return(status: 200,
                                                                body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Condition.category").to_return(status: 200,
                                                                   body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Condition.clinicalStatus").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}Condition.code").to_return(status: 200,
                                                               body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Condition.onset.as(dateTime)").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}Condition.subject.where(resolve() is Patient)").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}Device.patient").to_return(status: 200,
                                                               body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Device.type").to_return(status: 200,
                                                            body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}DiagnosticReport.category").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}DiagnosticReport.code").to_return(status: 200,
                                                                      body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}DiagnosticReport.effective").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}DiagnosticReport.subject.where(resolve() is Patient)").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}DiagnosticReport.status").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}DocumentReference.category").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}DocumentReference.date").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}DocumentReference.id").to_return(status: 200,
                                                                     body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}DocumentReference.subject.where(resolve() is Patient)").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}DocumentReference.context.period").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}DocumentReference.status").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}DocumentReference.type").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}Encounter.class").to_return(status: 200,
                                                                body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Encounter.period").to_return(status: 200,
                                                                 body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Encounter.id").to_return(status: 200,
                                                             body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Encounter.identifier").to_return(status: 200,
                                                                     body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Encounter.subject.where(resolve() is Patient)").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}Encounter.status").to_return(status: 200,
                                                                 body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Encounter.type").to_return(status: 200,
                                                               body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Patient.extension.where(url = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity').extension.value.code").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}Goal.lifecycleStatus").to_return(status: 200,
                                                                     body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Goal.subject.where(resolve() is Patient)").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}(Goal.target.due as date)").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}Immunization.occurrence").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}Immunization.patient").to_return(status: 200,
                                                                     body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Immunization.status").to_return(status: 200,
                                                                    body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Location.address.city").to_return(status: 200,
                                                                      body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Location.address.postalCode").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}Location.address.state").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}Location.address").to_return(status: 200,
                                                                 body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Location.name").to_return(status: 200,
                                                              body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}MedicationRequest.authoredOn").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}MedicationRequest.encounter").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}MedicationRequest.intent").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}MedicationRequest.subject.where(resolve() is Patient)").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}MedicationRequest.status").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}Observation.category").to_return(status: 200,
                                                                     body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Observation.code").to_return(status: 200,
                                                                 body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Observation.effective").to_return(status: 200,
                                                                      body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Observation.subject.where(resolve() is Patient)").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}Observation.status").to_return(status: 200,
                                                                   body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Organization.address").to_return(status: 200,
                                                                     body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Organization.name").to_return(status: 200,
                                                                  body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Patient.birthDate").to_return(status: 200,
                                                                  body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Patient.name.family").to_return(status: 200,
                                                                    body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Patient.gender").to_return(status: 200,
                                                               body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Patient.name.given").to_return(status: 200,
                                                                   body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Patient.id").to_return(status: 200,
                                                           body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Patient.identifier").to_return(status: 200,
                                                                   body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Patient.name").to_return(status: 200,
                                                             body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Practitioner.identifier").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}Practitioner.name").to_return(status: 200,
                                                                  body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}PractitionerRole.practitioner").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}PractitionerRole.specialty").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}Procedure.code").to_return(status: 200,
                                                               body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Procedure.performed").to_return(status: 200,
                                                                    body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Procedure.subject.where(resolve() is Patient)").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )
    stub_request(:post, "#{fhirpath}Procedure.status").to_return(status: 200,
                                                                 body: '[{"type": "code", "element": "notnull"}]')
    stub_request(:post, "#{fhirpath}Patient.extension.where(url = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-race').extension.value.code").to_return(
      status: 200, body: '[{"type": "code", "element": "notnull"}]'
    )

    result = described_class.new.check(context)[0]

    # rubocop:disable Layout/LineLength
    expect(result.message).to eq("Found SearchParameters with no searchable data in examples: \n\thttp://hl7.org/fhir/us/core/SearchParameter/us-core-practitionerrole-practitioner\n\thttp://hl7.org/fhir/us/core/SearchParameter/us-core-practitionerrole-specialty")
    # rubocop:enable Layout/LineLength
  end
end
