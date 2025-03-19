# frozen_string_literal: true

require 'extract_tgz_helper'
require_relative '../../../../../lib/inferno/dsl/fhir_evaluation/evaluation_context'

def fixture(filename)
  path = File.join(uscore3_untarred, 'package', filename)
  FHIR::Json.from_json(File.read(path))
end

RSpec.describe Inferno::DSL::FHIREvaluation::Rules::ValueSetsDemonstrate do
  include ExtractTGZHelper

  let(:uscore3_package) { File.realpath(File.join(Dir.pwd, 'spec/fixtures/uscore311.tgz')) }
  let(:uscore3_untarred) { extract_tgz(uscore3_package) }

  let(:patient85) do
    path = File.expand_path('../../../../../spec/fixtures/patient_85.json', __dir__)
    FHIR::Json.from_json(File.read(path))
  end

  after { cleanup(uscore3_untarred) }

  # rubocop:disable Layout/LineLength
  it 'test with US Core 3.1.1 search params and example data included in the IG' do
    # ig = Inferno::Entities::IG.from_file('spec/fixtures/uscore311.tgz')

    # data = [patient85.entry[0].resource]
    value_sets_to_load = ['ValueSet-us-core-observation-smokingstatus.json']
    profiles = value_sets_to_load.map { |e| fixture(e.to_s) }
    ig = instance_double(Inferno::Entities::IG, profiles:)

    smoking_status_obs = patient85.entry.map(&:resource).find do |r|
      r.resourceType == 'Observation' && r.code.text == 'Tobacco smoking status'
    end
    data = [smoking_status_obs]
    context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data,
                                                                  Inferno::DSL::FHIREvaluation::Config.new, nil)

    stub_request(:get, 'http://hl7.org/fhir/us/core/ValueSet/us-core-smoking-status-observation-codes').to_return(
      status: 200, body: '', headers: {}
    )
    stub_request(:get, 'http://hl7.org/fhir/us/core/ValueSet/us-core-vital-signs').to_return(status: 200, body: '',
                                                                                             headers: {})
    stub_request(:get, 'http://hl7.org/fhir/us/core/ValueSet/birthsex').to_return(status: 200, body: '', headers: {})
    stub_request(:get, 'http://hl7.org/fhir/us/core/ValueSet/omb-ethnicity-category').to_return(status: 200, body: '',
                                                                                                headers: {})
    stub_request(:get, 'http://hl7.org/fhir/us/core/ValueSet/omb-race-category').to_return(status: 200, body: '',
                                                                                           headers: {})
    stub_request(:get, 'http://hl7.org/fhir/us/core/ValueSet/us-core-clinical-note-type').to_return(status: 200,
                                                                                                    body: '', headers: {})
    stub_request(:get, 'http://hl7.org/fhir/us/core/ValueSet/us-core-condition-category').to_return(status: 200,
                                                                                                    body: '', headers: {})
    stub_request(:get, 'http://hl7.org/fhir/us/core/ValueSet/us-core-condition-code').to_return(status: 200, body: '',
                                                                                                headers: {})
    stub_request(:get, 'http://hl7.org/fhir/us/core/ValueSet/us-core-diagnosticreport-category').to_return(status: 200,
                                                                                                           body: '', headers: {})
    stub_request(:get, 'http://hl7.org/fhir/us/core/ValueSet/us-core-documentreference-type').to_return(status: 200,
                                                                                                        body: '', headers: {})
    stub_request(:get, 'http://hl7.org/fhir/us/core/ValueSet/us-core-narrative-status').to_return(status: 200,
                                                                                                  body: '', headers: {})
    stub_request(:get, 'http://hl7.org/fhir/us/core/ValueSet/us-core-observation-smoking-status-status').to_return(
      status: 200, body: '', headers: {}
    )
    stub_request(:get, 'http://hl7.org/fhir/us/core/ValueSet/detailed-ethnicity').to_return(status: 200, body: '',
                                                                                            headers: {})
    stub_request(:get, 'http://hl7.org/fhir/us/core/ValueSet/detailed-race').to_return(status: 200, body: '',
                                                                                       headers: {})
    stub_request(:get, 'http://hl7.org/fhir/us/core/ValueSet/simple-language').to_return(status: 200, body: '',
                                                                                         headers: {})
    stub_request(:get, 'http://hl7.org/fhir/us/core/ValueSet/us-core-diagnosticreport-lab-codes').to_return(
      status: 200, body: '', headers: {}
    )
    stub_request(:get, 'http://hl7.org/fhir/us/core/ValueSet/us-core-diagnosticreport-report-and-note-codes').to_return(
      status: 200, body: '', headers: {}
    )
    stub_request(:get, 'http://hl7.org/fhir/us/core/ValueSet/us-core-documentreference-category').to_return(
      status: 200, body: '', headers: {}
    )
    stub_request(:get, 'http://hl7.org/fhir/us/core/ValueSet/us-core-encounter-type').to_return(status: 200, body: '',
                                                                                                headers: {})
    stub_request(:get, 'http://hl7.org/fhir/us/core/ValueSet/us-core-observation-smokingstatus-max').to_return(
      status: 200, body: '', headers: {}
    )
    stub_request(:get, 'http://hl7.org/fhir/us/core/ValueSet/us-core-observation-value-codes').to_return(status: 200,
                                                                                                         body: '', headers: {})
    stub_request(:get, 'http://hl7.org/fhir/us/core/ValueSet/us-core-procedure-code').to_return(status: 200, body: '',
                                                                                                headers: {})
    stub_request(:get, 'http://hl7.org/fhir/us/core/ValueSet/us-core-provenance-participant-type').to_return(
      status: 200, body: '', headers: {}
    )
    stub_request(:get, 'http://hl7.org/fhir/us/core/ValueSet/us-core-provider-role').to_return(status: 200, body: '',
                                                                                               headers: {})
    stub_request(:get, 'http://hl7.org/fhir/us/core/ValueSet/us-core-usps-state').to_return(status: 200, body: '',
                                                                                            headers: {})
    stub_request(:get, 'https://hl7.org/fhir/us/core/CodeSystem/us-core-provenance-participant-type').to_return(
      status: 200, body: '', headers: {}
    )
    stub_request(:get, 'https://hl7.org/fhir/sid/icd-10-cm').to_return(status: 200, body: '', headers: {})
    stub_request(:get, 'https://hl7.org/fhir/sid/icd-9-cm').to_return(status: 200, body: '', headers: {})
    stub_request(:get, 'https://hl7.org/fhir/us/core/CodeSystem/us-core-documentreference-category').to_return(
      status: 200, body: '', headers: {}
    )

    result = described_class.new.check(context)[0]
    expect(result.severity).to eq('warning')

    # let(:patient85) do
    #   fixture('patient_85.json')
    # end

    # it 'identifies used valuesets' do
    #   value_sets_to_load = [
    #     'ValueSet-us-core-observation-smokingstatus.json'
    #   ]
    #   value_sets = value_sets_to_load.map { |e| fixture("#{e}") }
    #   ig = instance_double(Inferno::Entities::IG, value_sets:)
    #   smoking_status_obs = patient85.entry.map(&:resource).find do |r|
    #     r.resourceType == 'Observation' && r.code.text == 'Tobacco smoking status'
    #   end
    #   data = [smoking_status_obs]
    #   context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data, nil, Inferno::DSL::FHIREvaluation::Config.new)

    #   result = described_class.new.check(context)[0]

    #   expect(result.severity).to eq('success')
    #   expect(result.message).to eq("All Value sets are used in Examples:\n\thttp://hl7.org/fhir/us/core/ValueSet/us-core-observation-smokingstatus is used 1 times in 1 resources")
    # end

    # it 'identifies unused valuesets' do
    #   value_sets_to_load = [
    #     'ValueSet-us-core-observation-smokingstatus.json'
    #   ]
    #   value_sets = value_sets_to_load.map { |e| fixture("#{e}") }
    #   ig = instance_double(Inferno::Entities::IG, value_sets:)
    #   data = [FHIR::Observation.new]
    #   context = Inferno::DSL::FHIREvaluation::EvaluationContext.new(ig, data, nil, Inferno::DSL::FHIREvaluation::Config.new)

    #   result = described_class.new.check(context)[0]

    #   expect(result.message).to eq("All codes in these value sets are used at least once in Examples:\nFound unused Value Sets: \n\thttp://hl7.org/fhir/us/core/ValueSet/us-core-observation-smokingstatus")
    # end
  end
  # rubocop:enable Layout/LineLength
end
