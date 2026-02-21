require_relative 'connection'
require_relative 'errors'

module Inferno
  module CLI
    module Session
      class SessionData
        include Connection
        include Errors
        attr_accessor :session_id, :options

        def initialize(session_id, options)
          self.session_id = session_id
          self.options = options
        end

        def run
          check_session_exists
          inputs = session_data

          puts JSON.pretty_generate(inputs)
          exit(0)
        end

        def session_data
          @session_data ||= data_for_session(session_id)
        end

        def data_for_session(id)
          response = connection.get("api/test_sessions/#{id}/session_data", nil, content_type: 'application/json')
          handle_web_api_error(response, :session_data) if response.status != 200

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
