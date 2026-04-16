require 'faraday'
require_relative 'connection'
require_relative 'errors'
require_relative 'session_status'

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
          puts JSON.pretty_generate(cancel_run(last_test_run))
          exit(0)
        end

        def cancel_run(current_run)
          run_id = current_run['id']

          unless CANCELLABLE_STATUSES.include?(current_run['status'])
            error = { errors: "Run '#{run_id}' cannot be cancelled: status is '#{current_run['status']}'" }
            puts JSON.pretty_generate(error)
            exit(3)
          end

          response = delete("api/test_runs/#{run_id}")
          handle_web_api_error(response, :cancel_run) if response.status != 204
          { run_id: run_id, cancelled: true }
        end

        def last_test_run
          SessionStatus.new(session_id, options).last_test_run
        end
      end
    end
  end
end
