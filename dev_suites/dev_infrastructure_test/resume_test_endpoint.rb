class ResumeTestEndpoint < Inferno::DSL::SuiteEndpoint
  def test_run_identifier
    'ABC'
  end

  def update_result
    results_repo.update(result.id, result: 'pass')
  end

  def make_response
    response.format = :json
    response.body = { test_id: test.id, requests_repo_class: requests_repo.class.name }.to_json
  end
end
