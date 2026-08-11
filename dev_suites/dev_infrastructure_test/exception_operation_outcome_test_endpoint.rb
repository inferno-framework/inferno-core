class ExceptionOperationOutcomeTestEndpoint < Inferno::DSL::SuiteEndpoint
  error_response_format :operation_outcome

  def test_run_identifier
    'ABC'
  end

  def make_response
    raise StandardError, 'BOOM_MAKE_RESPONSE'
  end
end
