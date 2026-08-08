class NoSessionTestEndpoint < Inferno::DSL::SuiteEndpoint
  def test_run_identifier
    'NONEXISTENT_IDENTIFIER'
  end
end
