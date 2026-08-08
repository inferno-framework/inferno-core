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

  describe '.error_response_format' do
    it 'raises an ArgumentError when given an unrecognized format' do
      expect do
        Class.new(described_class) { error_response_format :bogus_format }
      end.to raise_error(
        ArgumentError,
        'Unknown error_response_format `:bogus_format`. Must be one of text, operation_outcome.'
      )
    end
  end

  describe 'when no matching test session is found' do
    it 'defaults to a plain text 500 response' do
      post '/custom/infra_test/no_session_test'

      expect(last_response.status).to eq(500)
      expect(last_response.body).to eq(
        "Unable to find test run for request to 'http://example.org/custom/infra_test/no_session_test': " \
        "identifier 'NONEXISTENT_IDENTIFIER' is not associated with a waiting session."
      )
    end

    it 'uses a different message when the test run identifier is blank' do
      post '/custom/infra_test/blank_identifier_test'

      expect(last_response.status).to eq(500)
      expect(last_response.body).to eq(
        "Unable to find test run for request to 'http://example.org/custom/infra_test/blank_identifier_test': " \
        'no identifier found.'
      )
    end

    it 'appends the test_run_identifier_location_description when the endpoint provides one' do
      post '/custom/infra_test/identifier_description_test'

      expect(last_response.status).to eq(500)
      expect(last_response.body).to eq(
        'Unable to find test run for request to ' \
        "'http://example.org/custom/infra_test/identifier_description_test': " \
        "identifier 'NONEXISTENT_IDENTIFIER', found in the 'code' query parameter, " \
        'is not associated with a waiting session.'
      )
    end

    it 'returns a FHIR OperationOutcome as application/fhir+json when configured to do so' do
      post '/custom/infra_test/operation_outcome_test'

      expect(last_response.status).to eq(500)
      expect(last_response.headers['Content-Type']).to eq('application/fhir+json')

      outcome = FHIR::OperationOutcome.new(JSON.parse(last_response.body))
      expect(outcome.issue.first.severity).to eq('fatal')
      expect(outcome.issue.first.code).to eq('not-found')
      expect(outcome.issue.first.details.text).to eq(
        "Unable to find test run for request to 'http://example.org/custom/infra_test/operation_outcome_test': " \
        "identifier 'NONEXISTENT_IDENTIFIER' is not associated with a waiting session."
      )
    end

    it 'uses a fully custom no_session_response override and still halts the request' do
      post '/custom/infra_test/custom_no_session_response_test'

      expect(last_response.status).to eq(404)
      expect(last_response.headers['Content-Type']).to eq('application/json; charset=utf-8')
      expect(JSON.parse(last_response.body)).to eq('error' => 'no matching session')
    end
  end

  describe 'when an error is raised while determining the test run identifier' do
    it 'logs the error and defaults to a plain text 500 response' do
      allow(Inferno::Application[:logger]).to receive(:error)

      post '/custom/infra_test/identifier_error_test'

      # No test run/session has been resolved yet at this point, so no session is logged.
      expect(Inferno::Application[:logger]).to have_received(:error)
        .with(%r{\A\[http://example.org/custom/infra_test/identifier_error_test\] (?!session=).*BOOM_IDENTIFIER}m)
      expect(last_response.status).to eq(500)
      expect(last_response.body).to include('An error occurred while determining the test run identifier')
      expect(last_response.body).to include('BOOM_IDENTIFIER')
    end

    it 'returns a FHIR OperationOutcome as application/fhir+json when configured to do so' do
      post '/custom/infra_test/identifier_error_operation_outcome_test'

      expect(last_response.status).to eq(500)
      expect(last_response.headers['Content-Type']).to eq('application/fhir+json')

      outcome = FHIR::OperationOutcome.new(JSON.parse(last_response.body))
      expect(outcome.issue.first.severity).to eq('fatal')
      expect(outcome.issue.first.code).to eq('exception')
      expect(outcome.issue.first.details.text).to eq(
        'An error occurred while determining the test run identifier for this request.'
      )
      expect(outcome.issue.first.diagnostics).to include('BOOM_IDENTIFIER')
    end
  end

  describe 'when an unhandled exception is raised while processing the request' do
    it 'logs the error and defaults to a plain text 500 response' do
      allow(Inferno::Application[:logger]).to receive(:error)

      post '/custom/infra_test/exception_test'

      # test_run has already been resolved by this point, so the session is included in the log.
      log_url = Regexp.escape('http://example.org/custom/infra_test/exception_test')
      expect(Inferno::Application[:logger]).to have_received(:error).with(
        /\A\[#{log_url}\] session=#{test_run.test_session_id}.*BOOM_MAKE_RESPONSE/m
      )
      expect(last_response.status).to eq(500)
      expect(last_response.body).to include('An error occurred while processing this request')
      expect(last_response.body).to include('BOOM_MAKE_RESPONSE')
    end

    it 'returns a FHIR OperationOutcome as application/fhir+json when configured to do so' do
      post '/custom/infra_test/exception_operation_outcome_test'

      expect(last_response.status).to eq(500)
      expect(last_response.headers['Content-Type']).to eq('application/fhir+json')

      outcome = FHIR::OperationOutcome.new(JSON.parse(last_response.body))
      expect(outcome.issue.first.severity).to eq('fatal')
      expect(outcome.issue.first.code).to eq('exception')
      expect(outcome.issue.first.details.text).to eq('An error occurred while processing this request.')
      expect(outcome.issue.first.diagnostics).to include('BOOM_MAKE_RESPONSE')
    end
  end

  describe 'when update_result causes the test run to resume' do
    it 'resumes the test run and exposes the repo accessor methods' do
      allow(Inferno::Jobs).to receive(:perform)

      post '/custom/infra_test/resume_test'

      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body['test_id']).to eq(InfrastructureTest::Suite.groups.first.groups.first.tests.first.id)
      expect(body['requests_repo_class']).to eq('Inferno::Repositories::Requests')

      expect(Inferno::Jobs).to have_received(:perform)
        .with(Inferno::Jobs::ResumeTestRun, test_run.id,
              { tags: ['source:suite_endpoint',
                       "session:#{test_run.test_session_id}",
                       'run:basic',
                       'test:infra_test-outer_inline_group-inner_inline_group-inline_test_1'] })
      expect(Inferno::Repositories::TestRuns.new.find(test_run.id).status).to eq('queued')
    end
  end

  describe 'when persisting the incoming request fails' do
    it 'logs the error instead of raising' do
      allow(Inferno::Application[:logger]).to receive(:error)
      allow_any_instance_of(Inferno::Repositories::Requests)
        .to receive(:create).and_raise(StandardError, 'BOOM_PERSIST')

      post '/custom/infra_test/json_test',
           { json_param: 'EXPECTED_RESPONSE_BODY' }.to_json,
           'CONTENT_TYPE' => 'application/json'

      expect(last_response.body).to eq('EXPECTED_RESPONSE_BODY')
      expect(Inferno::Application[:logger]).to have_received(:error).with(/BOOM_PERSIST/)
    end
  end
end
