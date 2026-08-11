class ExceptionTestEndpoint < Inferno::DSL::SuiteEndpoint
  def test_run_identifier
    'ABC'
  end

  def make_response
    raise StandardError, 'BOOM_MAKE_RESPONSE'
  end
end
