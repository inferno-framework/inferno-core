require_relative '../../../dev_suites/uscore_v3.1.1/uscore_suite'
require_relative '../../../dev_suites/uscore_v3.1.1/groups/allergy_intolerance/allergy_intolerance_search_patient'
require_relative '../../request_helper'

RSpec.describe USCore::AllergyIntoleranceSearchPatientTest do
  include Rack::Test::Methods
  include RequestHelpers

  fixture_path = File.join(File.expand_path(__dir__), 'us_core_allergyintolerance.json')

  # must include entire suite-group-test id in order for fhir_client to be inherited
  let(:test) { Inferno::Repositories::Tests.new.find('ONCProgram-Group02-USCore::AllergyIntoleranceSequence-Group01-allergy_intolerance_search_params_validation') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'ONCProgram') }
  let(:allergy_intolerance_resource) { FHIR.from_contents(File.read(fixture_path)) }

  def run(runnable, inputs = {}, scratch = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(test_session_id: test_session.id, name: name, value: value)
    end
    Inferno::TestRunner.new(test_session: test_session, test_run: test_run).run(test_run.runnable, scratch)
  end

  it 'passes when Allergy Intolerance resource returned matches search parameters' do
    inputs = {}
    scratch = {}
    scratch[:resources_returned] = [allergy_intolerance_resource]
    scratch[:search_parameters_used] = { patient: 'example' }
    result = run(test, inputs, scratch)
    expect(result.result).to eq('pass')

    scratch[:search_parameters_used] = { patient: 'Patient/example' }
    result = run(test, inputs, scratch)
    expect(result.result).to eq('pass')

    
    scratch[:search_parameters_used] = { 'patient': 'example', 'clinical-status': 'active' }
    result = run(test, inputs, scratch)
    expect(result.result).to eq('pass')
  end

  it 'fails if search parameter doesn not match' do
    inputs = {}
    scratch = {}
    scratch[:resources_returned] = [allergy_intolerance_resource]
    scratch[:search_parameters_used] = { patient: 'wrong-patient' }
    result = run(test, inputs, scratch)
    expect(result.result).to eq('fail')

    scratch[:search_parameters_used] = { patient: 'AllergyIntolerance/example' }
    result = run(test, inputs, scratch)
    expect(result.result).to eq('fail')

    
    scratch[:search_parameters_used] = { 'patient': 'example', 'clinical-status': 'inactive' }
    result = run(test, inputs, scratch)
    expect(result.result).to eq('fail')
  end
end
