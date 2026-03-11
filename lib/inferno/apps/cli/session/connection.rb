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
          @base_url ||= if options[:inferno_base_url].present?
                          options[:inferno_base_url]
                        else
                          Inferno::Application['base_url']
                        end
        end

        def check_session_exists
          response = connection.get("api/test_sessions/#{session_id}", nil, content_type: 'application/json')
          handle_web_api_error(response, :session_details) if response.status != 200
        end
      end
    end
  end
end
