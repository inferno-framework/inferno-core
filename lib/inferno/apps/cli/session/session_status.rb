require 'faraday'
require_relative 'connection'
require_relative 'errors'

module Inferno
  module CLI
    module Session
      class SessionStatus
        include Connection
        include Errors
        attr_accessor :session_id, :options

        def initialize(session_id, options)
          self.session_id = session_id
          self.options = options
        end

        def run
          session_status = last_test_run
          run_id = session_status['id']
          last_test_executed = last_test_executed(run_id)
          session_status['last_test_executed'] = last_test_executed['test_id']
          if session_status['status'] == 'waiting'
            session_status['wait_outputs'] = last_test_executed['outputs']
            session_status['wait_result_message'] = last_test_executed['result_message']
          end

          puts JSON.pretty_generate(session_status)
          exit(0)
        end

        def last_test_run
          response = connection.get("api/test_sessions/#{session_id}/last_test_run", content_type: 'application/json')
          handle_web_api_error(response, :last_session_run) if response.status != 200
          JSON.parse(response.body)
        end

        def last_test_executed(run_id)
          results = run_results(run_id)
          results.reverse.find { |result| result['test_id'].present? }
        end

        def run_results(run_id)
          response = connection.get("api/test_runs/#{run_id}/results", content_type: 'application/json')
          handle_web_api_error(response, :test_run_results) if response.status != 200
          JSON.parse(response.body)
        end

        def suite_options_list
          options[:suite_options].keys.map do |option|
            { id: option, value: options[:suite_options][option] }
          end
        end
      end
    end
  end
end
