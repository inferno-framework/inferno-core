require 'hanami-controller'

module Inferno
  module DSL
    # A base class for creating routes to resume test execution upon receiving
    # an incoming request.
    # @private
    # @see Inferno::DSL::Runnable#resume_test_route
    class ResumeTestRoute
      include Hanami::Action
      include Import[
                requests_repo: 'inferno.repositories.requests',
                results_repo: 'inferno.repositories.results',
                test_runs_repo: 'inferno.repositories.test_runs',
                tests_repo: 'inferno.repositories.tests'
              ]

      def self.call(params)
        new.call(params)
      end

      # The incoming request
      #
      # @return [Inferno::Entities::Request]
      def request
        @request ||= Inferno::Entities::Request.from_rack_env(@params.env)
      end

      # @private
      def test_run
        @test_run ||=
          test_runs_repo.find_latest_waiting_by_identifier(test_run_identifier)
      end

      # @private
      def waiting_result
        @waiting_result ||= results_repo.find_waiting_result(test_run_id: test_run.id)
      end

      # @private
      def update_result
        results_repo.pass_waiting_result(waiting_result.id)
      end

      # @private
      def persist_request
        requests_repo.create(
          request.to_hash.merge(
            test_session_id: test_run.test_session_id,
            result_id: waiting_result.id,
            name: test.config.request_name(test.incoming_request_name)
          )
        )
      end

      # @private
      def redirect_route
        "#{Application['base_url']}/test_sessions/#{test_run.test_session_id}##{resume_ui_at_id}"
      end

      # @private
      def test
        @test ||= tests_repo.find(waiting_result.test_id)
      end

      # @private
      def resume_ui_at_id
        test_run.test_suite_id || test_run.test_group_id || test.parent.id
      end

      # @private
      def call(_params)
        if test_run.nil?
          status(500, "Unable to find test run with identifier '#{test_run_identifier}'.")
          return
        end

        test_runs_repo.mark_as_no_longer_waiting(test_run.id)

        update_result
        persist_request

        Jobs.perform(Jobs::ResumeTestRun, test_run.id)

        redirect_to redirect_route
      end
    end
  end
end
