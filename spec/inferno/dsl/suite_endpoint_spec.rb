RSpec.describe Inferno::DSL::SuiteEndpoint, :request do
  let(:test_run) do
    repo_create(:test_run, identifier: 'ABC', status: 'waiting', wait_timeout: Time.now + 5.minutes)
  end

  before do
    repo_create(
      :result,
      test_run_id: test_run.id,
      result: 'wait',
      test_id: InfrastructureTest::Suite.groups.first.groups.first.tests.first.id,
      test_suite_id: nil
    )
  end

  it 'automatically parses application/json bodies' do
    post '/custom/infra_test/json_test',
         { json_param: 'EXPECTED_RESPONSE_BODY' }.to_json,
         'CONTENT_TYPE' => 'application/json'

    expect(last_response.body).to eq('EXPECTED_RESPONSE_BODY')
  end

  it 'automatically parses application/fhir+json bodies' do
    post '/custom/infra_test/json_test',
         { json_param: 'EXPECTED_RESPONSE_BODY' }.to_json,
         'CONTENT_TYPE' => 'application/fhir+json'

    expect(last_response.body).to eq('EXPECTED_RESPONSE_BODY')
  end

  describe 'when no matching test session is found' do
    it 'defaults to a plain text 500 response' do
      post '/custom/infra_test/no_session_test'

      expect(last_response.status).to eq(500)
      expect(last_response.body).to eq(
        "Unable to find test run with identifier 'NONEXISTENT_IDENTIFIER'."
      )
    end

    it 'uses a different message when the test run identifier is blank' do
      post '/custom/infra_test/blank_identifier_test'

      expect(last_response.status).to eq(500)
      expect(last_response.body).to eq('No test identifier found.')
    end

    it 'returns a FHIR OperationOutcome as application/fhir+json when configured to do so' do
      post '/custom/infra_test/operation_outcome_test'

      expect(last_response.status).to eq(500)
      expect(last_response.headers['Content-Type']).to eq('application/fhir+json')

      outcome = FHIR::OperationOutcome.new(JSON.parse(last_response.body))
      expect(outcome.issue.first.severity).to eq('fatal')
      expect(outcome.issue.first.code).to eq('not-found')
      expect(outcome.issue.first.details.text).to eq(
        "Unable to find test run with identifier 'NONEXISTENT_IDENTIFIER'."
      )
    end

    it 'uses a fully custom no_session_response override and still halts the request' do
      post '/custom/infra_test/custom_no_session_response_test'

      expect(last_response.status).to eq(404)
      expect(last_response.headers['Content-Type']).to eq('application/json; charset=utf-8')
      expect(JSON.parse(last_response.body)).to eq('error' => 'no matching session')
    end
  end
end
