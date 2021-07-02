require 'hanami-controller'

module Inferno
  module DSL
    class ResumeTestRoute
      include Hanami::Action
      include Import[
                requests_repo: 'repositories.requests',
                results_repo: 'repositories.results',
                test_runs_repo: 'repositories.test_runs',
                tests_repo: 'repositories.tests'
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

      # @api private
      def test_run
        @test_run ||=
          test_runs_repo.find_latest_waiting_by_identifier(test_run_identifier)
      end

      # @api private
      def waiting_result
        @waiting_result ||= results_repo.find_waiting_result(test_run_id: test_run.id)
      end

      # @api private
      def update_result
        results_repo.update_result_and_message(waiting_result.id, 'pass', nil)
      end

      # @api private
      def persist_request
        requests_repo.create(
          request.to_hash.merge(
            test_session_id: test_run.test_session_id,
            result_id: waiting_result.id,
            name: test.incoming_request_name
          )
        )
      end

      # @api private
      def redirect_route
        "/test_sessions/#{test_run.test_session_id}##{waiting_group_id}"
      end

      # @api private
      def test
        @test ||= tests_repo.find(waiting_result.test_id)
      end

      # @api private
      def waiting_group_id
        test.parent.id
      end

      # @api private
      def call(_params)
        if test_run.nil?
          status(500, "Unable to find test run with identifier '#{test_run_identifier}'.")
          return
        end

        test_runs_repo.update_identifier(test_run.id, nil)

        update_result
        persist_request

        redirect_to redirect_route
      end
    end
  end
end
