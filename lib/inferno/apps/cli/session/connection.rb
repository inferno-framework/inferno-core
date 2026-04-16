module Inferno
  module CLI
    module Session
      module Connection
        def connection
          @connection ||= Faraday.new(
            base_url,
            request: { timeout: 600 }
          )
        end

        def base_url
          @base_url ||=
            "#{(options[:inferno_base_url].presence || Inferno::Application['base_url']).to_s.delete_suffix('/')}/"
        end

        def get(path, params = nil, headers = {})
          connection.get(path, params, headers)
        rescue Faraday::Error => e
          handle_connection_error(e)
        end

        def post(path, body = nil, headers = {})
          connection.post(path, body, headers)
        rescue Faraday::Error => e
          handle_connection_error(e)
        end

        def delete(path, params = nil, headers = {})
          connection.delete(path, params, headers)
        rescue Faraday::Error => e
          handle_connection_error(e)
        end

        def handle_connection_error(error)
          puts JSON.pretty_generate({ errors: "Could not connect to Inferno at '#{base_url}': #{error.message}" })
          exit(3)
        end

        def check_session_exists
          response = get("api/test_sessions/#{session_id}", nil, content_type: 'application/json')
          handle_web_api_error(response, :session_details) if response.status != 200
        end
      end
    end
  end
end
