module Inferno
  module Utils
    # @api private
    module Middleware
      class RequestLogger
        attr_reader :app

        def initialize(app)
          @app = app
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

          response
        end

        def log_response(response, start_time, end_time, exception = nil)
          elapsed = end_time - start_time
          status, _response_headers, body = response if response
          status, = response if exception

          logger.info("#{status} in #{elapsed.in_milliseconds} ms")
          if body.present?
            if body.length > 100
              logger.info("#{body[0..100]}...")
            else
              logger.info(body)
            end
          end
        end

        def log_request(env)
          method = env['REQUEST_METHOD']
          scheme = env['rack.url_scheme']
          host = env['HTTP_HOST']
          path = env['REQUEST_URI']
          query = env['rack.request.query_string']
          body = env['rack.input']
          body = body.instance_of?(Puma::NullIO) ? nil : body.string
          query_string = query.blank? ? '' : "?#{query}"

          logger.info("#{method} #{scheme}://#{host}#{path}#{query_string}")
          if body.present?
            if body.length > 100
              logger.info("#{body[0..100]}...")
            else
              logger.info(body)
            end
          end
        end
      end
    end
  end
end
