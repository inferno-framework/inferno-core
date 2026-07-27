class ResumeTestEndpoint < Inferno::DSL::SuiteEndpoint
  def test_run_identifier
    'RESUME_ENDPOINT_ID'
  end

  def update_result
    results_repo.update(result.id, result: 'pass')
  end
end
