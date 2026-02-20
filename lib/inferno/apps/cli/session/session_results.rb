require_relative 'connection'
require_relative 'errors'

module Inferno
  module CLI
    module Session
      class SessionResults
        include Connection
        include Errors
        attr_accessor :session_id, :options

        def initialize(session_id, options)
          self.session_id = session_id
          self.options = options
        end

        def run
          check_session_exists
          results = session_results

          puts JSON.pretty_generate(results)
          exit(0)
        end

        def session_results
          @session_results ||= results_for_session(session_id)
        end

        def results_for_session(id)
          response = connection.get("api/test_sessions/#{id}/results", nil, content_type: 'application/json')
          handle_web_api_error(response, :session_results) if response.status != 200

          JSON.parse(response.body)
        end

        def check_session_exists
          session_details_response = connection.get("api/test_sessions/#{session_id}", nil,
                                                    content_type: 'application/json')
          handle_web_api_error(session_details_response, :session_details) if session_details_response.status != 200
        end
      end
    end
  end
end
