module DevelopmentTestKit
  class JSONTestEndpoint < Inferno::DSL::SuiteEndpoint
    def test_run_identifier
      'ABC'
    end

    def make_response
      response.body = req.params[:json_param]
    end
  end
end
