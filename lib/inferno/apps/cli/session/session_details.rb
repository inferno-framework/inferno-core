require 'faraday'
require_relative 'connection'
require_relative 'errors'

module Inferno
  module CLI
    module Session
      class SessionDetails
        include Connection
        include Errors

        attr_accessor :session_id, :options

        def initialize(session_id, options)
          self.session_id = session_id
          self.options = options
        end

        def details_for_session
          response = get("api/test_sessions/#{session_id}", nil, content_type: 'application/json')
          handle_web_api_error(response, :session_details) if response.status != 200
          JSON.parse(response.body)
        end
      end
    end
  end
end
