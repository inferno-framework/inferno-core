require 'puma/null_io'

module Inferno
  module Utils
    # @private
    module Middleware
      # This middleware handles persisting the incoming requests to
      # Inferno::DSL::SuiteEndpoint. It is also responsible for resuming test
      # runs which those endpoints indicate should be resumed, because the test
      # runs can't be resumed prior to the incoming request being persisted.
      class RequestRecorder
        attr_reader :app

        def initialize(app)
          @app = app
        end

        def logger
          @logger ||= Application['logger']
        end

        def call(env) # rubocop:disable Metrics/CyclomaticComplexity
          env['rack.after_reply'] ||= []
          env['rack.after_reply'] << proc do
            next unless env['inferno.persist_request']

            repo = Inferno::Repositories::Requests.new

            uri = URI('http://example.com')
            uri.scheme = env['rack.url_scheme']
            uri.host = env['SERVER_NAME']
            uri.port = env['SERVER_PORT']
            uri.path = env['REQUEST_PATH'] || ''
            uri.query = env['rack.request.query_string']
            url = uri&.to_s
            verb = env['REQUEST_METHOD']
            logger.info('get body')
            request_body = env['rack.input']
            request_body.rewind if env['rack.input'].respond_to? :rewind
            request_body = request_body.instance_of?(Puma::NullIO) ? nil : request_body.string

            request_headers = Rack::Request.new(env).headers.to_h.map { |name, value| { name:, value: } }

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

          response = app.call(env)

          # For some reason, response isn't in scope for the proc above. This
          # ensures that the response is available to the proc so that all
          # details of the response can be persisted.
          env['inferno.response'] = response

          # rack.after_reply is handled by puma, which doesn't process requests
          # in unit tests, so we manually run them when in the test environment
          env['rack.after_reply'].each(&:call) if (ENV['APP_ENV'] = 'test')

          env['inferno.response']
        rescue StandardError => e
          logger.error(e.full_message)

          env['inferno.response'] = response
        end
      end
    end
  end
end
