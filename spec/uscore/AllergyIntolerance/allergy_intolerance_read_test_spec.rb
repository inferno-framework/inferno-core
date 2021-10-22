require_relative '../../../dev_suites/uscore_v3.1.1/uscore_suite'
require_relative '../../../dev_suites/uscore_v3.1.1/groups/allergy_intolerance/allergy_intolerance_search_patient'
require_relative '../../request_helper'

RSpec.describe USCore::AllergyIntoleranceSearchPatientTest do
  include Rack::Test::Methods
  include RequestHelpers

  fixture_path = File.join(File.expand_path(__dir__), 'us_core_allergyintolerance.json')

  # must include entire suite-group-test id in order for fhir_client to be inherited
  let(:test) { Inferno::Repositories::Tests.new.find('ONCProgram-Group02-USCore::AllergyIntoleranceSequence-allergy_intolerance_read_test') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'ONCProgram') }
  let(:url) { 'http://example.com/fhir' }
  let(:allergy_intolerance_resource) { FHIR.from_contents(File.read(fixture_path)) }

  def run(runnable, inputs = {}, scratch = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(test_session_id: test_session.id, name: name, value: value)
    end
    Inferno::TestRunner.new(test_session: test_session, test_run: test_run).run(test_run.runnable, scratch)
  end

  it 'passes when a valid Allergy Intolerance resource is received' do
    inputs = {
      url: url,
      standalone_patient_id: 'example'
    }
    scratch = {
      allergy_intolerance_resources: [allergy_intolerance_resource]
    }
    stub_request(:get, "#{url}/AllergyIntolerance/#{allergy_intolerance_resource.id}")
      .to_return(status: 200, body: allergy_intolerance_resource.to_json, headers: { 'Content-Type' => 'application/json' })
    result = run(test, inputs, scratch)

    expect(result.result).to eq('pass')
  end

  it 'skips if no allergy intolerance resource found' do
    inputs = {}
    scratch = {}
    result = run(test, inputs, scratch)

    expect(result.result).to eq('skip')
  end

  it 'fails if bad response' do
    inputs = {
      url: url,
      standalone_patient_id: 'example'
    }
    scratch = {
      allergy_intolerance_resources: [allergy_intolerance_resource]
    }
    stub_request(:get, "#{url}/AllergyIntolerance/#{allergy_intolerance_resource.id}")
      .to_return(status: 401)
    result = run(test, inputs, scratch)

    expect(result.result).to eq('fail')
  end

  it 'fails if resource returned does not match id' do
    inputs = {
      url: url,
      standalone_patient_id: 'example'
    }
    scratch = {
      allergy_intolerance_resources: [allergy_intolerance_resource]
    }
    
    wrong_allergy_intolerance = FHIR::AllergyIntolerance.new(id: 'something wrong')
    stub_request(:get, "#{url}/AllergyIntolerance/#{allergy_intolerance_resource.id}")
      .to_return(status: 200, body: wrong_allergy_intolerance.to_json, headers: { 'Content-Type' => 'application/json' })
    result = run(test, inputs, scratch)

    expect(result.result).to eq('fail')
  end

  it 'fails if no resource returned' do
    inputs = {
      url: url,
      standalone_patient_id: 'example'
    }
    scratch = {
      allergy_intolerance_resources: [allergy_intolerance_resource]
    }
    
    stub_request(:get, "#{url}/AllergyIntolerance/#{allergy_intolerance_resource.id}")
      .to_return(status: 200, body: [].to_json, headers: { 'Content-Type' => 'application/json' })
    result = run(test, inputs, scratch)

    expect(result.result).to eq('fail')
  end
end
