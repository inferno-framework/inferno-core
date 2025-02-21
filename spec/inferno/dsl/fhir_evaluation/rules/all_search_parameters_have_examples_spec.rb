# frozen_string_literal: true

require_relative '../../../../../lib/inferno/dsl/fhir_evaluation/evaluation_context'

def fixture(file)
  path = File.expand_path("../../../../../spec/fixtures/#{file}", __dir__)
  FHIR::Json.from_json(File.read(path))
end

RSpec.describe Inferno::DSL::FHIREvaluation::Rules::AllSearchParametersHaveExamples do
  let(:patient85) do
    fixture('patient_85.json')
  end

  it 'passes search params with appropriate data' do
    searchparams_to_load = [
      'SearchParameter-us-core-patient-birthdate.json',
      'SearchParameter-us-core-patient-gender.json'
    ]
    profiles = searchparams_to_load.map { |e| fixture(e.to_s) }
    instance_double(Inferno::Entities::IG, profiles:)
    ig = Inferno::Entities::IG.from_file('spec/fixtures/uscore311_.tgz')
    # data = [patient85.entry[0].resource]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, ig.examples,
                                                                  Inferno::DSL::FHIREvaluation::Config.new, nil)

    stub_request(:post, "#{ENV.fetch('FHIRPATH_URL', nil)}/evaluate?path=Immunization.patient")
      .to_return(status: 200, body: '[]')

    stub_request(:post, "#{ENV.fetch('FHIRPATH_URL', nil)}/evaluate?path=Patient.birthDate")
      .to_return(status: 200, body: '[{"type": "date","element": "1940-03-29"}]')

    stub_request(:post, "#{ENV.fetch('FHIRPATH_URL', nil)}/evaluate?path=Patient.gender")
      .to_return(status: 200, body: '[{"type": "code", "element": "male"}]')

    result = described_class.new.check(context)[0]

    expect(result.message).to eq('All SearchParameters have examples')
  end

  # it 'warns on search params with missing data' do
  #   searchparams_to_load = [
  #     'SearchParameter-us-core-patient-birthdate.json',
  #     'SearchParameter-us-core-patient-gender.json'
  #   ]
  #   search_params = searchparams_to_load.map { |e| fixture("#{e}") }
  #   ig = Inferno::Entities::IG.from_file("spec/fixtures/uscore311.tgz")
  #   patient = FHIR::Patient.new(birthDate: '2022-02-22')
  #   data = [patient]
  #   context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data, Inferno::DSL::FHIREvaluation::Config.new, nil)

  #   stub_request(:post, "#{ENV.fetch('FHIRPATH_URL')}/evaluate?path=Patient.name")
  #   .to_return(status: 200, body: '[]')

  #   stub_request(:post, "#{ENV.fetch('FHIRPATH_URL')}/evaluate?path=Patient.name.given")
  #     .to_return(status: 200, body: '[]')

  #   stub_request(:post, "#{ENV.fetch('FHIRPATH_URL')}/evaluate?path=Patient.name.family")
  #     .to_return(status: 200, body: '[]')

  #   stub_request(:post, "#{ENV.fetch('FHIRPATH_URL')}/evaluate?path=Patient.identifier")
  #     .to_return(status: 200, body: '[]')

  #   stub_request(:post, "#{ENV.fetch('FHIRPATH_URL')}/evaluate?path=Patient.birthDate")
  #     .to_return(status: 200, body: '[{"type": "date","element": "2022-02-22"}]')

  #   stub_request(:post, "#{ENV.fetch('FHIRPATH_URL')}/evaluate?path=Patient.gender")
  #     .to_return(status: 200, body: '[]')

  #   result = described_class.new.check(context)[0]

  #   expect(result.message).to eq('Found SearchParameters with no searchable data: http://hl7.org/fhir/us/core/SearchParameter/us-core-patient-gender')
  # end
end
