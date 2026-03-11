module Inferno
  module CLI
    module Session
      module Errors
        def handle_web_api_error(response, api = nil)
          error = begin
            JSON.parse(response.body)
          rescue JSON::ParserError
            text_error =
              if response.body == 'Not Found'
                case api
                when :session_create, :run_create
                  "Running Inferno host not found at '#{base_url}'"
                when :session_details, :session_data, :last_session_run
                  "Session '#{session_id}' not found on Inferno host at '#{base_url}'"
                else
                  response.body
                end
              elsif api == :test_run_results && response.status == 500
                test_run_id = response.env.url.to_s.split('/')[-2]
                "Test Run '#{test_run_id}' for session '#{session_id} not found on Inferno host at '#{base_url}"
              else
                response.body
              end
            { errors: text_error }
          end

          puts JSON.pretty_generate(error)
          exit(3)
        end
      end
    end
  end
end
