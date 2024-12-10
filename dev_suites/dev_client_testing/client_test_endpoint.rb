class ClientTestEndpoint < Inferno::DSL::SuiteEndpoint
  def test_run_identifier
    request.params[:uid]
  end

  def make_response
    response.status = 200
    response.body = {status: 'ok'}.to_json
    response.format = :json
  end

  def update_result
    results_repo.update(result.id, result: 'pass')
  end

  def tags
    []
  end
end
