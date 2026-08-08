class CustomNoSessionResponseTestEndpoint < Inferno::DSL::SuiteEndpoint
  def test_run_identifier
    'NONEXISTENT_IDENTIFIER'
  end

  def no_session_response
    response.status = 404
    response.format = :json
    response.body = { error: 'no matching session' }.to_json
  end

  def make_response
    response.body = 'SHOULD_NOT_BE_REACHED'
  end
end
