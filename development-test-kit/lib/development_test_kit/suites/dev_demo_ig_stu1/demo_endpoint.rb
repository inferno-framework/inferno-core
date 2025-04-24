module DevelopmentTestKit
  class DemoEndpoint < Inferno::DSL::SuiteEndpoint
    def test_run_identifier
      request.headers['authorization']&.delete_prefix('Bearer ')
    end

    def make_response
      response.status = 200
      response.body = { abc: 123 }.to_json
      response.format = :json
    end

    def tags
      ['abc', 'def']
    end

    def name
      'custom_request'
    end

    def update_result
      results_repo.update(result.id, result: 'pass')
    end
  end
end
