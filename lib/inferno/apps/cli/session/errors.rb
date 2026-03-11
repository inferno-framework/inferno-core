module Inferno
  module CLI
    module Session
      module Errors
        def handle_web_api_error(response, api = nil)
          error = parse_error_response(response, api)
          puts JSON.pretty_generate(error)
          exit(3)
        end

        def parse_error_response(response, api)
          JSON.parse(response.body)
        rescue JSON::ParserError
          { errors: text_error_message(response, api) }
        end

        def text_error_message(response, api)
          if response.body == 'Not Found' || response.status == 404
            not_found_error_message(api)
          elsif api == :test_run_results && response.status == 500
            test_run_not_found_message(response)
          else
            response.body
          end
        end

        def not_found_error_message(api)
          case api
          when :session_create, :run_create
            "Running Inferno host not found at '#{base_url}'"
          when :session_details, :session_data, :last_session_run
            "Session '#{session_id}' not found on Inferno host at '#{base_url}'"
          else
            'Not Found'
          end
        end

        def test_run_not_found_message(response)
          test_run_id = response.env.url.to_s.split('/')[-2]
          "Test Run '#{test_run_id}' for session '#{session_id} not found on Inferno host at '#{base_url}"
        end
      end
    end
  end
end
