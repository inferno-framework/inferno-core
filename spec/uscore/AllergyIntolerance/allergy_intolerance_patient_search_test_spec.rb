require_relative '../../../dev_suites/uscore_v3.1.1/uscore_suite'
require_relative '../../../dev_suites/uscore_v3.1.1/groups/allergy_intolerance/allergy_intolerance_search_patient'
require_relative '../../request_helper'

RSpec.describe USCore::AllergyIntoleranceSearchPatientTest do
  include Rack::Test::Methods
  include RequestHelpers

  def wrap_resources_in_bundle(resources, type: 'searchset')
    resources = [resources].flatten.compact
    # get the Bundle class from the same version of FHIR models
    # bundle_class = resources.first.class.parent::Bundle
    bundle_class = FHIR::Bundle
    bundle = bundle_class.new('id': 'foo', 'type': type)
    resources.each do |resource|
      bundle.entry << bundle_class::Entry.new
      bundle.entry.last.resource = resource
    end
    bundle
  end

  fixture_path = File.join(File.expand_path(__dir__), 'us_core_allergyintolerance.json')

  # must include entire suite-group-test id in order for fhir_client to be inherited
  let(:test) { Inferno::Repositories::Tests.new.find('ONCProgram-Group02-USCore::AllergyIntoleranceSequence-Group01-allergy_intolerance_search_patient_test') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'ONCProgram') }
  let(:url) { 'http://example.com/fhir' }
  let(:allergy_intolerance_resource) { FHIR.from_contents(File.read(fixture_path)) }
  let(:allergy_intolerance_bundle) { wrap_resources_in_bundle(allergy_intolerance_resource).to_json }

  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(test_session_id: test_session.id, name: name, value: value)
    end
    Inferno::TestRunner.new(test_session: test_session, test_run: test_run).run(test_run.runnable)
  end

  def search_url(inputs)
    "#{inputs[:url]}/AllergyIntolerance?patient=#{inputs[:standalone_patient_id]}"
  end

  it 'passes when a valid Allergy Intolerance resource is received' do
    inputs = {
      url: url,
      standalone_patient_id: 'example'
    }
    stub_request(:get, search_url(inputs))
      .to_return(status: 200, body: allergy_intolerance_bundle, headers: { 'Content-Type' => 'application/json' })
    result = run(test, inputs)
    expect(result.result).to eq('pass')
  end

  it 'skips when no allergy intolerance is returned' do
    inputs = {
      url: url,
      standalone_patient_id: 'example'
    }
    empty_bundle = FHIR::Bundle.new('id': 'foo')
    stub_request(:get, search_url(inputs))
      .to_return(status: 200, body: empty_bundle.to_json, headers: { 'Content-Type' => 'application/json' })
    result = run(test, inputs)
    expect(result.result).to eq('skip')
  end

  it 'fails if bad response is returned' do
    inputs = {
      url: url,
      standalone_patient_id: 'example'
    }
    empty_bundle = FHIR::Bundle.new('id': 'foo')
    stub_request(:get, search_url(inputs))
      .to_return(status: 401)
    result = run(test, inputs)
    expect(result.result).to eq('fail')
  end
end
