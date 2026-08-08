class IdentifierErrorOperationOutcomeTestEndpoint < Inferno::DSL::SuiteEndpoint
  error_response_format :operation_outcome

  def test_run_identifier
    raise StandardError, 'BOOM_IDENTIFIER'
  end
end
