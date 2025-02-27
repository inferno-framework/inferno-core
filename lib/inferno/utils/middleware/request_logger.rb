require 'puma/null_io'

module Inferno
  module Utils
    # @private
    module Middleware
      class RequestLogger
        attr_reader :app

        def initialize(app)
          @app = app
        end

        def verbose_logging?
          @verbose_logging ||= ENV['VERBOSE_REQUEST_LOGGING']&.downcase == true
        end

        def logger
          @logger ||= Application['logger']
        end

        def call(env)
          start = Time.now
          log_request(env)
          begin
            response = app.call(env)
            log_response(response, start, Time.now)
          rescue StandardError => e
            log_response([500, nil, nil], start, Time.now, e)
            raise e
          end

          env['inferno.response'] = response

          # rack.after_reply is handled by puma, which doesn't process requests
          # in unit tests, so we manually run them when in the test environment
          env['rack.after_reply']&.each(&:call) if ENV['APP_ENV'] == 'test'

          response
        end

        def log_response(response, start_time, end_time, exception = nil)
          elapsed = end_time - start_time
          status, _response_headers, body = response if response
          status, = response if exception

          logger.info("#{status} in #{elapsed.in_milliseconds} ms")
          return unless body.present?

          body = body.join if body.is_a?(Array)

          if body.length > 100 && !verbose_logging?
            logger.info("#{body[0..100]}...")
          else
            logger.info(body)
          end
        end

        def log_request(env)
          method = env['REQUEST_METHOD']
          scheme = env['rack.url_scheme']
          host = env['HTTP_HOST']
          path = env['REQUEST_URI']
          query = env['rack.request.query_string']
          body = env['rack.input']
          body =
            if body.instance_of? Puma::NullIO
              nil
            else
              contents = body.read
              body.rewind
              contents
            end
          query_string = query.blank? ? '' : "?#{query}"

          logger.info("#{method} #{scheme}://#{host}#{path}#{query_string}")

          return unless body.present?

          if body.length > 100 && !verbose_logging?
            logger.info("#{body[0..100]}...")
          else
            logger.info(body)
          end
        end
      end
    end
  end
end
