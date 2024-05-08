require 'hanami/controller'
require_relative '../ext/rack'

module Inferno
  module DSL
    # A base class for creating endpoints to test client requests. This class is
    # based on Hanami::Action, and may be used similarly to [a normal Hanami
    # endpoint](https://github.com/hanami/controller/tree/v2.0.0).
    #
    # @example
    # class AuthorizedEndpoint < Inferno::DSL::SuiteEndpoint
    #   # Identify the incoming request based on a bearer token
    #   def test_run_identifier
    #     request.header['authorization']&.delete_prefix('Bearer ')
    #   end
    #
    #   # Return a json FHIR Patient resource
    #   def make_response
    #     response.status = 200
    #     response.body = FHIR::Patient.new(id: 'abcdef').to_json
    #     response.format = :json
    #   end
    #
    #   # Update the waiting test to pass when the incoming request is received.
    #   # This will resume the test run.
    #   def update_result
    #     results_repo.update(result.id, result: 'pass')
    #   end
    #
    #   # Apply the 'authorized' tag to the incoming request so that it may be
    #   # used by later tests.
    #   def tags
    #     ['authorized']
    #   end
    # end
    #
    # class AuthorizedRequestSuite < Inferno::TestSuite
    #   id :authorized_suite
    #   suite_endpoint :get, '/authorized_endpoint', AuthorizedEndpoint
    #
    #   group do
    #     title 'Authorized Request Group'
    #
    #     test do
    #       title 'Wait for authorized request'
    #
    #       input :bearer_token
    #
    #       run do
    #         wait(
    #           identifier: bearer_token,
    #           message: "Waiting to receive a request with bearer_token: #{bearer_token}" \
    #                    "at `#{Inferno::Application['base_url']}/custom/authorized_suite/authorized_endpoint`"
    #         )
    #       end
    #     end
    #   end
    # end
    class SuiteEndpoint < Hanami::Action
      attr_reader :req, :res

      # @!group Overrides These methods should be overridden by subclasses to
      #   define the behavior of the endpoint

      # Override this method to determine a test run's identifier based on an
      # incoming request.
      #
      # @return [String]
      #
      # @example
      # def test_run_identifier
      #   # Identify the test session of an incoming request based on the bearer
      #   # token
      #   request.headers['authorization']&.delete_prefix('Bearer ')
      # end
      def test_run_identifier
        nil
      end

      # Override this method to build the response.
      #
      # @return [Void]
      #
      # @example
      # def make_response
      #   response.status = 200
      #   response.body = { abc: 123 }.to_json
      #   response.format = :json
      # end
      def make_response
        nil
      end

      # Override this method to define the tags which will be applied to the
      # request.
      #
      # @return [Array<String>]
      def tags
        @tags ||= []
      end

      # Override this method to assign a name to the request
      #
      # @return [String]
      def name
        result&.runnable&.incoming_request_name
      end

      # Override this method to update the current waiting result. To resume the
      # test run, set the result to something other than 'waiting'.
      #
      # @return [Void]
      #
      # @example
      # def update_result
      #   results_repo.update(result.id, result: 'pass')
      # end
      def update_result
        nil
      end

      # Override this method to specify whether this request should be
      # persisted. Defaults to true.
      #
      # @return [Boolean]
      def persist_request?
        true
      end

      # @!endgroup

      # @private
      def self.call(...)
        new.call(...)
      end

      # @return [Inferno::Repositories::Requests]
      def requests_repo
        @requests_repo ||= Inferno::Repositories::Requests.new
      end

      # @return [Inferno::Repositories::Results]
      def results_repo
        @results_repo ||= Inferno::Repositories::Results.new
      end

      # @return [Inferno::Repositories::TestRuns]
      def test_runs_repo
        @test_runs_repo ||= Inferno::Repositories::TestRuns.new
      end

      # @return [Inferno::Repositories::Tests]
      def tests_repo
        @tests_repo ||= Inferno::Repositories::Tests.new
      end

      # @private
      def initialize(config: self.class.config) # rubocop:disable Lint/MissingSuper
        @config = config
      end

      # The incoming request as a `Hanami::Action::Request`
      #
      # @return [Hanami::Action::Request]
      #
      # @example
      # request.params               # Get url/query params
      # request.body.read            # Get body
      # request.headers['accept']    # Get Accept header
      def request
        req
      end

      # The response as a `Hanami::Action::Response`. Modify this to build the
      # response to the incoming request.
      #
      # @return [Hanami::Action::Response]
      #
      # @example
      # response.status = 200        # Set the status
      # response.body = 'Ok'         # Set the body
      # # Set headers
      # response.headers.merge!('X-Custom-Header' => 'CUSTOM_HEADER_VALUE')
      def response
        res
      end

      # The test run which is waiting for incoming requests
      #
      # @return [Inferno::Entities::TestRun]
      def test_run
        @test_run ||=
          test_runs_repo.find_latest_waiting_by_identifier(find_test_run_identifier).tap do |test_run|
            halt 500, "Unable to find test run with identifier '#{test_run_identifier}'." if test_run.nil?
          end
      end

      # The result which is waiting for incoming requests for the current test
      # run
      #
      # @return [Inferno::Entities::Result]
      def result
        @result ||= find_result
      end

      # The test which is currently waiting for incoming requests
      #
      # @return [Inferno::Entities::Test]
      def test
        @test ||= tests_repo.find(result.test_id)
      end

      # @private
      def find_test_run_identifier
        @test_run_identifier ||= test_run_identifier
      rescue StandardError => e
        halt 500, "Unable to determine test run identifier:\n#{e.full_message}"
      end

      # @private
      def find_result
        results_repo.find_waiting_result(test_run_id: test_run.id)
      end

      # @private
      # The actual persisting happens in
      # Inferno::Utils::Middleware::RequestRecorder, which allows the response
      # to include response headers added by other parts of the rack stack
      # rather than only the response headers explicitly added in the endpoint.
      def persist_request
        req.env['inferno.persist_request'] = true
        req.env['inferno.test_session_id'] = test_run.test_session_id
        req.env['inferno.result_id'] = result.id
        req.env['inferno.tags'] = tags
        req.env['inferno.name'] = name if name.present?
      end

      # @private
      def resume_test_run?
        find_result&.result != 'waiting'
      end

      # @private
      # Inferno::Utils::Middleware::RequestRecorder actually resumes the
      # TestRun. If it were resumed here, it would be resuming prior to the
      # Request being persisted.
      def resume
        req.env['inferno.resume_test_run'] = true
        req.env['inferno.test_run_id'] = test_run.id
      end

      # @private
      def handle(req, res)
        @req = req
        @res = res
        test_run

        persist_request if persist_request?

        update_result

        resume if resume_test_run?

        make_response
      rescue StandardError => e
        halt 500, e.full_message
      end
    end
  end
end
