class IdentifierErrorTestEndpoint < Inferno::DSL::SuiteEndpoint
  def test_run_identifier
    raise StandardError, 'BOOM_IDENTIFIER'
  end
end
