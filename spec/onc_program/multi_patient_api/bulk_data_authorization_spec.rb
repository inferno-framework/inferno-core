require 'pry' #TODO: Remove
require_relative '../../../dev_suites/dev_multi_patient_api/bulk_data_access/bulk_data_authorization'
require_relative '../../../dev_suites/dev_multi_patient_api/bulk_data_access/bulk_data_utils'

RSpec.describe MultiPatientAPI::BulkDataAuthorization do 

  include BulkDataUtils

  let(:suite) { Inferno::Repositories::TestSuites.new.find('multi_patient_api') }
  let(:group) { Inferno::Repositories::TestGroups.new.find('bulk_data_authorization') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'multi_patient_api') }
  let(:bulk_token_endpoint) { 'http://example.com/fhir' }
  let(:bulk_encryption_method) { 'ES384' }
  let(:bulk_scope) { 'system/Patient.read' }
  let(:bulk_client_id) { 'clientID' }
  let(:default_input) { {
    bulk_token_endpoint: bulk_token_endpoint,
    bulk_encryption_method: bulk_encryption_method,
    bulk_scope: bulk_scope,
    bulk_client_id: bulk_client_id
  } }

  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(test_session_id: test_session.id, name: name, value: value)
    end 
    Inferno::TestRunner.new(test_session: test_session, test_run: test_run).run(runnable)
  end 


  # Issue --> client assertion in body of request_content does not match the 
  # client assertion in the body of post request made in the runnable. The
  # nitty gritty: JTI is randomly generated, and then used to create a JWT_token.
  # So, even though key is the same, the token being signed is changed. 
  def test_client_credentials(runnable, credentials_change, expectation)

    authorization_inputs = {
      encryption_method: bulk_encryption_method,
      scope: bulk_scope,
      iss: bulk_client_id,
      sub: bulk_client_id,
      aud: bulk_token_endpoint
    }.merge(credentials_change)

    # request_content = build_authorization_request(authorization_inputs)

    # stub_request(:post, bulk_token_endpoint)
    #   .with(
    #     body: request_content[:body],
    #     headers: {
    #       'Accept'=>'application/json',
    #       'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
    #       'Content-Type'=>'application/x-www-form-urlencoded',
    #       'User-Agent'=>'Faraday v1.2.0'
    #     })
    #   .to_return(status: 400, body: "", headers: {})
    
    result = run(runnable, default_input)
    expect(result.result).to eq(expectation)

  end 

  # TODO: After TLS tester class is implemented, create this test 
  describe 'endpoint TLS tests' do

  end 
 
  describe '[Invalid grant_type] test' do
    let(:runnable) { group.tests[1] }

    it 'passes when token endpoint requires valid grant_type' do 
      #credentials_change = { grant_type: 'not_a_grant_type' }
      #test_client_credentials(runnable, credentials_change, 'pass')
    end 

    it 'fails when token endpoint does not require a grant_type header' do 

    end 

    it 'fails when token endpoint allows invalid grant_type' do 

    end 
  end 

end 