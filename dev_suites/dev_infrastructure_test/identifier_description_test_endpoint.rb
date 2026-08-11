class IdentifierDescriptionTestEndpoint < Inferno::DSL::SuiteEndpoint
  def test_run_identifier
    'NONEXISTENT_IDENTIFIER'
  end

  def test_run_identifier_location_description
    "the 'code' query parameter"
  end
end
