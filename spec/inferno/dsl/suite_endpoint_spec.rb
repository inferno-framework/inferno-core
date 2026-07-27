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

  describe 'resuming a test run' do
    let(:resume_test_run) do
      repo_create(:test_run, identifier: 'RESUME_ENDPOINT_ID', status: 'waiting', wait_timeout: Time.now + 5.minutes)
    end
    let(:resume_test_id) { InfrastructureTest::Suite.groups.first.groups.first.tests.first.id }

    before do
      repo_create(
        :result,
        test_run_id: resume_test_run.id,
        result: 'wait',
        test_id: resume_test_id,
        test_suite_id: nil
      )
    end

    it 'enqueues a ResumeTestRun job tagged with the source, session, run, and test' do
      allow(Inferno::Jobs).to receive(:perform)

      post '/custom/infra_test/resume_test', {}.to_json, 'CONTENT_TYPE' => 'application/json'

      expect(Inferno::Jobs).to have_received(:perform).with(
        Inferno::Jobs::ResumeTestRun,
        resume_test_run.id,
        tags: contain_exactly(
          'source:suite_endpoint',
          "session:#{resume_test_run.test_session_id}",
          "run:#{resume_test_run.test_suite_id || resume_test_run.test_group_id || resume_test_run.test_id}",
          "test:#{resume_test_id}"
        )
      )
    end
  end
end
