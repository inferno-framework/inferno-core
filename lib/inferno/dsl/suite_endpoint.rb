require 'hanami/controller'
require 'rack/request'
require 'fhir_models'
require_relative '../ext/rack'

module Inferno
  module DSL
    # A base class for creating endpoints to test client requests. This class is
    # based on Hanami::Action, and may be used similarly to [a normal Hanami
    # endpoint](https://github.com/hanami/controller/tree/v2.0.0).
    #
    # @example
    #     class AuthorizedEndpoint < Inferno::DSL::SuiteEndpoint
    #       # Identify the incoming request based on a bearer token
    #       def test_run_identifier
    #         request.headers['authorization']&.delete_prefix('Bearer ')
    #       end
    #
    #       error_response_format :operation_outcome
    #
    #       # Return a json FHIR Patient resource
    #       def make_response
    #         response.status = 200
    #         response.body = FHIR::Patient.new(id: 'abcdef').to_json
    #         response.format = :json
    #       end
    #
    #       # Update the waiting test to pass when the incoming request is received.
    #       # This will resume the test run.
    #       def update_result
    #         results_repo.update(result.id, result: 'pass')
    #       end
    #
    #       # Apply the 'authorized' tag to the incoming request so that it may be
    #       # used by later tests.
    #       def tags
    #         ['authorized']
    #       end
    #     end
    #
    #     class AuthorizedRequestSuite < Inferno::TestSuite
    #       id :authorized_suite
    #       suite_endpoint :get, '/authorized_endpoint', AuthorizedEndpoint
    #
    #       group do
    #         title 'Authorized Request Group'
    #
    #         test do
    #           title 'Wait for authorized request'
    #
    #           input :bearer_token
    #
    #           run do
    #             wait(
    #               identifier: bearer_token,
    #               message: "Waiting to receive a request with bearer_token: #{bearer_token}" \
    #                        "at `#{Inferno::Application['base_url']}/custom/authorized_suite/authorized_endpoint`"
    #             )
    #           end
    #         end
    #       end
    #     end
    #
    class SuiteEndpoint < Hanami::Action
      attr_reader :req, :res

      # The built-in options for `error_response_format`
      ERROR_RESPONSE_FORMATS = [:text, :operation_outcome].freeze

      class << self
        # Select one of Inferno's standard response formats to be returned
        # whenever Inferno has to render an error response of its own due
        # to problems finding the target session or an unhandled exception.
        # You can override {#no_session_response} to customize the response
        # in the no-session case.
        #
        # * `:text` (default): a `500` response with a plain text message
        # * `:operation_outcome`: a `500` response with a FHIR
        #   `OperationOutcome` serialized as `application/fhir+json`
        #
        # @param format [Symbol] `:text` or `:operation_outcome`
        # @return [void]
        #
        # @example
        #   class MyEndpoint < Inferno::DSL::SuiteEndpoint
        #     error_response_format :operation_outcome
        #   end
        def error_response_format(format)
          unless ERROR_RESPONSE_FORMATS.include?(format)
            raise ArgumentError,
                  "Unknown error_response_format `#{format.inspect}`. " \
                  "Must be one of #{ERROR_RESPONSE_FORMATS.join(', ')}."
          end

          @error_response_format_value = format
        end

        # @private
        def error_response_format_value
          @error_response_format_value ||= :text
        end
      end

      # @!group Overrides These methods should be overridden by subclasses to
      #   define the behavior of the endpoint

      # Override this method to determine a test run's identifier based on an
      # incoming request.
      #
      # @return [String]
      #
      # @example
      #   def test_run_identifier
      #     # Identify the test session of an incoming request based on the bearer
      #     # token
      #     request.headers['authorization']&.delete_prefix('Bearer ')
      #   end
      def test_run_identifier
        nil
      end

      # Override this method to build the response.
      #
      # @return [Void]
      #
      # @example
      #   def make_response
      #     response.status = 200
      #     response.body = { abc: 123 }.to_json
      #     response.format = :json
      #   end
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
      #   def update_result
      #     results_repo.update(result.id, result: 'pass')
      #   end
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

      # Override this method to fully customize the response returned when no
      # waiting test run/session can be found for the incoming request. Set
      # `response.status` and `response.body` (and `response.content_type`, if
      # needed) — Inferno halts the request with those values. By default,
      # this renders one of Inferno's standard responses based on the format
      # selected with `error_response_format` (a plain text `500` response if
      # none was selected).
      #
      # @return [Void]
      #
      # @example
      #   def no_session_response
      #     response.status = 404
      #     response.format = :json
      #     response.body = { error: 'no matching session' }.to_json
      #   end
      def no_session_response
        error_response(no_session_message, code: 'not-found')
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
      #   request.params               # Get url/query params
      #   request.body.read            # Get body
      #   request.headers['accept']    # Get Accept header
      def request
        req
      end

      # The response as a `Hanami::Action::Response`. Modify this to build the
      # response to the incoming request.
      #
      # @return [Hanami::Action::Response]
      #
      # @example
      #   response.status = 200        # Set the status
      #   response.body = 'Ok'         # Set the body
      #   # Set headers
      #   response.headers.merge!('X-Custom-Header' => 'CUSTOM_HEADER_VALUE')
      def response
        res
      end

      # The test run which is waiting for incoming requests
      #
      # @return [Inferno::Entities::TestRun]
      def test_run
        @test_run ||=
          test_runs_repo.find_latest_waiting_by_identifier(find_test_run_identifier).tap do |test_run|
            render_error_and_halt { no_session_response } if test_run.nil?
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

      # @return [Logger] Inferno's logger
      def logger
        @logger ||= Application['logger']
      end

      # @private
      def find_test_run_identifier
        @test_run_identifier ||= test_run_identifier
      rescue StandardError => e
        logger.error(e.full_message)
        render_error_and_halt do
          error_response(
            'An error occurred while determining the test run identifier for this request.',
            code: 'exception',
            diagnostics: e.full_message
          )
        end
      end

      # @private
      def no_session_message
        if test_run_identifier.blank?
          'No test identifier found.'
        else
          "Unable to find test run with identifier '#{test_run_identifier}'."
        end
      end

      # @private
      # Yields to build the response, then halts with whatever ended up in
      # `response.status`/`response.body`. Centralizing the halt here means
      # overrides of the response-building hooks (e.g. #no_session_response)
      # never need to remember to call `halt` themselves.
      def render_error_and_halt
        yield
        halt response.status, response.body.join
      end

      # @private
      # `message` is a short, human-readable summary (goes in the
      # OperationOutcome issue's `details.text`, or stands alone as the whole
      # plain text body). `diagnostics`, if given, is technical detail — e.g.
      # an exception's full backtrace — that goes in the issue's
      # `diagnostics` element, or is appended to the plain text body.
      def error_response(message, code:, diagnostics: nil)
        case self.class.error_response_format_value
        when :operation_outcome
          operation_outcome_error_response(message, code:, diagnostics:)
        else
          text_error_response(message, diagnostics:)
        end
      end

      # @private
      def text_error_response(message, diagnostics: nil)
        response.status = 500
        response.body = diagnostics ? "#{message}\n#{diagnostics}" : message
      end

      # @private
      def operation_outcome_error_response(message, code:, diagnostics: nil)
        issue = FHIR::OperationOutcome::Issue.new(
          severity: 'fatal',
          code:,
          details: FHIR::CodeableConcept.new(text: message)
        )
        issue.diagnostics = diagnostics if diagnostics

        response.status = 500
        response.content_type = 'application/fhir+json'
        response.body = FHIR::OperationOutcome.new(issue: [issue]).to_json
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
        req.env['inferno.test_session_id'] = test_run.test_session_id
        req.env['inferno.result_id'] = result.id
        req.env['inferno.tags'] = tags
        req.env['inferno.name'] = name if name.present?

        add_persistence_callback
      end

      # @private
      def resume_test_run?
        find_result&.result != 'wait'
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
        logger.error(e.full_message)
        render_error_and_halt do
          error_response(
            'An error occurred while processing this request.',
            code: 'exception',
            diagnostics: e.full_message
          )
        end
      end

      # @private
      def add_persistence_callback # rubocop:disable Metrics/CyclomaticComplexity
        logger = Application['logger']
        env = req.env
        env['rack.after_reply'] ||= []
        env['rack.after_reply'] << proc do
          repo = Inferno::Repositories::Requests.new

          uri = URI('http://example.com')
          uri.scheme = env['rack.url_scheme']
          uri.host = env['SERVER_NAME']
          uri.port = env['SERVER_PORT']
          uri.path = env['REQUEST_PATH'] || ''
          uri.query = env['rack.request.query_string'] if env['rack.request.query_string'].present?
          url = uri&.to_s
          verb = env['REQUEST_METHOD']
          request_body = env['rack.input']
          request_body.rewind if env['rack.input'].respond_to? :rewind
          request_body = request_body.instance_of?(Puma::NullIO) ? nil : request_body.string

          request_headers = ::Rack::Request.new(env).headers.to_h.map { |name, value| { name:, value: } }

          status, response_headers, response_body = env['inferno.response']

          response_headers = response_headers.map { |name, value| { name:, value: } }

          repo.create(
            verb:,
            url:,
            direction: 'incoming',
            name: env['inferno.name'],
            status:,
            request_body:,
            response_body: response_body.join,
            result_id: env['inferno.result_id'],
            test_session_id: env['inferno.test_session_id'],
            request_headers:,
            response_headers:,
            tags: env['inferno.tags']
          )

          if env['inferno.resume_test_run']
            test_run_id = env['inferno.test_run_id']
            Inferno::Repositories::TestRuns.new.mark_as_no_longer_waiting(test_run_id)

            Inferno::Jobs.perform(Jobs::ResumeTestRun, test_run_id)
          end
        rescue StandardError => e
          logger.error(e.full_message)
        end
      end
    end
  end
end
