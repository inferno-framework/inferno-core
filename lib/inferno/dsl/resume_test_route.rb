require 'hanami/controller'

module Inferno
  module DSL
    # A base class for creating routes to resume test execution upon receiving
    # an incoming request.
    # @private
    # @see Inferno::DSL::Runnable#resume_test_route
    class ResumeTestRoute < Hanami::Action
      include Import[
                requests_repo: 'inferno.repositories.requests',
                results_repo: 'inferno.repositories.results',
                test_runs_repo: 'inferno.repositories.test_runs',
                tests_repo: 'inferno.repositories.tests'
              ]

      def self.call(...)
        new.call(...)
      end

      # @private
      def test_run_identifier_block
        self.class.singleton_class.instance_variable_get(:@test_run_identifier_block)
      end

      # @private
      def find_test_run(test_run_identifier)
        test_runs_repo.find_latest_waiting_by_identifier(test_run_identifier)
      end

      # @private
      def find_waiting_result(test_run)
        results_repo.find_waiting_result(test_run_id: test_run.id)
      end

      # @private
      def update_result(waiting_result)
        results_repo.pass_waiting_result(waiting_result.id)
      end

      # @private
      def persist_request(request, test_run, waiting_result, test)
        requests_repo.create(
          request.to_hash.merge(
            test_session_id: test_run.test_session_id,
            result_id: waiting_result.id,
            name: test.config.request_name(test.incoming_request_name)
          )
        )
      end

      # @private
      def redirect_route(test_run, test)
        "#{Application['base_url']}/test_sessions/#{test_run.test_session_id}##{resume_ui_at_id(test_run, test)}"
      end

      # @private
      def find_test(waiting_result)
        tests_repo.find(waiting_result.test_id)
      end

      # @private
      def resume_ui_at_id(test_run, test)
        test_run.test_suite_id || test_run.test_group_id || test.parent.id
      end

      # @private
      def handle(req, res)
        request = Inferno::Entities::Request.from_hanami_request(req)

        test_run_identifier = instance_exec(request, &test_run_identifier_block)

        test_run = find_test_run(test_run_identifier)

        halt 500, "Unable to find test run with identifier '#{test_run_identifier}'." if test_run.nil?

        test_runs_repo.mark_as_no_longer_waiting(test_run.id)

        waiting_result = find_waiting_result(test_run)
        test = find_test(waiting_result)

        update_result(waiting_result)
        persist_request(request, test_run, waiting_result, test)

        Jobs.perform(Jobs::ResumeTestRun, test_run.id)

        res.redirect_to redirect_route(test_run, test)
      end
    end
  end
end
