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
end
