class OperationOutcomeTestEndpoint < Inferno::DSL::SuiteEndpoint
  no_session_response_format :operation_outcome

  def test_run_identifier
    'NONEXISTENT_IDENTIFIER'
  end
end
