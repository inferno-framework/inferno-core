module Inferno
  module Utils
    # @private
    module Middleware
      class RequestRecorder
        attr_reader :app

        def initialize(app)
          @app = app
        end

        def logger
          @logger ||= Application['logger']
        end

        def call(env)
          env['rack.after_reply'] ||= []
          env['rack.after_reply'] << proc do
            next unless env['inferno.persist_request']

            repo = Inferno::Repositories::Requests.new

            uri = URI('http://example.com')
            uri.scheme = env['rack.url_scheme']
            uri.host = env['SERVER_NAME']
            uri.port = env['SERVER_PORT']
            uri.path = env['REQUEST_PATH']
            uri.query = env['rack.request.query_string']
            url = uri.to_s
            verb = env['REQUEST_METHOD']
            logger.info('get body')
            request_body = env['rack.input']
            request_body = request_body.instance_of?(Puma::NullIO) ? nil : request_body.string

            request_headers = Rack::Request.new(env).headers.to_h.map { |name, value| { name:, value: } }

            status, response_headers, response_body = @response

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
          rescue StandardError => e
            logger.error(e.full_message)
          end

          @response = app.call(env)
        rescue StandardError => e
          logger.error(e.full_message)

          @response
        end
      end
    end
  end
end
