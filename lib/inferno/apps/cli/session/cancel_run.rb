require 'faraday'
require_relative 'connection'
require_relative 'errors'

module Inferno
  module CLI
    module Session
      class CancelRun
        include Connection
        include Errors
        attr_accessor :session_id, :options

        CANCELLABLE_STATUSES = %w[queued running waiting].freeze

        def initialize(session_id, options)
          self.session_id = session_id
          self.options = options
        end

        def run
          current_run = last_test_run
          run_id = current_run['id']

          unless CANCELLABLE_STATUSES.include?(current_run['status'])
            puts "Run #{run_id} has status '#{current_run['status']}' and cannot be cancelled."
            exit(3)
          end

          response = connection.delete("api/test_runs/#{run_id}")
          handle_web_api_error(response, :cancel_run) if response.status != 204
          puts "Run #{run_id} cancelled."
          exit(0)
        end

        def last_test_run
          response = connection.get("api/test_sessions/#{session_id}/last_test_run",
                                    content_type: 'application/json')
          handle_web_api_error(response, :last_session_run) if response.status != 200
          JSON.parse(response.body)
        end
      end
    end
  end
end
