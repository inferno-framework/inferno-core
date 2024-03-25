require_relative 'suite_endpoint'

module Inferno
  module DSL
    # A base class for creating routes to resume test execution upon receiving
    # an incoming request.
    # @private
    # @see Inferno::DSL::Runnable#resume_test_route
    class ResumeTestRoute < SuiteEndpoint
      # The incoming request
      #
      # @return [Inferno::Entities::Request]
      def request
        @request ||= Inferno::Entities::Request.from_hanami_request(req)
      end

      # @private
      def test_run_identifier
        @test_run_identifier ||= instance_exec(request, &test_run_identifier_block)
      end

      # @private
      def tags
        self.class.singleton_class.instance_variable_get(:@tags) || []
      end

      # @private
      def update_result
        results_repo.update_result(result.id, new_result)
      end

      # @private
      def make_response
        res.redirect_to redirect_route(test_run, test)
      end

      # @private
      def name
        test.config.request_name(test.incoming_request_name)
      end

      # @private
      def test_run_identifier_block
        self.class.singleton_class.instance_variable_get(:@test_run_identifier_block)
      end

      # @private
      def new_result
        self.class.singleton_class.instance_variable_get(:@new_result)
      end

      # @private
      def redirect_route(test_run, test)
        "#{Application['base_url']}/test_sessions/#{test_run.test_session_id}##{resume_ui_at_id(test_run, test)}"
      end

      # @private
      def resume_ui_at_id(test_run, test)
        test_run.test_suite_id || test_run.test_group_id || test.parent.id
      end
    end
  end
end
