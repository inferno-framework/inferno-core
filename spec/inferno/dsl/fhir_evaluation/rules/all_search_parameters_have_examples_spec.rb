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

  describe 'with a small IG' do
    let(:fhirpath_url) { "#{ENV.fetch('FHIRPATH_URL')}/evaluate?path=" }
    let(:found_body) { '[{"type": "string", "element": "found"}]' }
    let(:patients) { [FHIR::Patient.new(id: 'patient-1'), FHIR::Patient.new(id: 'patient-2')] }
    let(:observation) { FHIR::Observation.new(id: 'observation-1', status: 'final') }
    let(:name_param) do
      FHIR::SearchParameter.new(url: 'http://example.com/SearchParameter/patient-name', base: ['Patient'],
                                expression: 'Patient.name')
    end

    def check(search_params, data)
      ig = instance_double(Inferno::Entities::IG, resources_by_type: { 'SearchParameter' => search_params })
      context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data,
                                                                    Inferno::DSL::FHIREvaluation::Config.new, nil)
      described_class.new.check(context)
      context.results
    end

    it 'skips the rule with a warning when FHIRPATH_URL is not set' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('FHIRPATH_URL').and_return(nil)

      results = check([name_param], patients)

      expect(results.map(&:severity)).to eq(['warning'])
      expect(results.first.message).to eq('FHIRPATH_URL is not found. Skipping rule AllSearchParametersHaveExamples.')
    end

    it 'reports success when every search parameter matches an example' do
      stub_request(:post, "#{fhirpath_url}Patient.name")
        .to_return({ status: 200, body: '[]' }, { status: 200, body: found_body })

      results = check([name_param], [observation] + patients)

      expect(results.map(&:severity)).to eq(['success'])
      expect(results.first.message).to eq('All SearchParameters have examples.')
    end

    it 'reports information when the IG has no search parameters' do
      results = check([], patients)

      expect(results.map(&:severity)).to eq(['information'])
      expect(results.first.message).to eq('IG contains no SearchParameter.')
    end

    it 'warns about a search parameter with no expression and reports it as unused' do
      param = FHIR::SearchParameter.new(url: 'http://example.com/SearchParameter/no-expression', base: ['Patient'])

      results = check([param], patients)

      expect(results.map(&:message)).to eq(
        [
          "Search parameter #{param.url} doesn't include an expression.",
          "Found SearchParameters with no searchable data in examples: \n\t#{param.url}"
        ]
      )
    end

    it 'reports an error when the FHIRPath service cannot be reached' do
      stub_request(:post, "#{fhirpath_url}Patient.name").to_raise(StandardError.new('boom'))

      results = check([name_param], patients)

      expect(results.first.severity).to eq('error')
      expect(results.first.message).to include('Unable to connect to FHIRPath service')
    end

    it 'warns when the FHIRPath service fails to evaluate an expression' do
      stub_request(:post, "#{fhirpath_url}Patient.name").to_return(status: 500, body: 'error')

      results = check([name_param], patients)

      expect(results.first.severity).to eq('warning')
      expect(results.first.message).to start_with(
        "SearchParameter #{name_param.url} failed to evaluate due to an error. Expression: Patient.name."
      )
    end
  end
end
