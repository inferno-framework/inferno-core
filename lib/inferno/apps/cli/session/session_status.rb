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
          session_status = status_for_session
          puts JSON.pretty_generate(session_status)
          exit(0)
        end

        def status_for_session
          session_status = last_test_run

          if session_status['id'].present?
            run_id = session_status['id']
            last_test_executed = last_test_executed(run_id)
            if last_test_executed.present?
              session_status['last_test_executed'] = last_test_executed['test_id']
              if session_status['status'] == 'waiting'
                session_status['wait_outputs'] = last_test_executed['outputs']
                session_status['wait_result_message'] = last_test_executed['result_message']
              end
            end
          end

          session_status
        end

        def last_test_run
          response = get("api/test_sessions/#{session_id}/last_test_run", nil,
                         content_type: 'application/json')
          handle_web_api_error(response, :last_session_run) if response.status != 200
          return JSON.parse(response.body) if response.body.present?

          # no execution has started yet for this session
          {
            'test_session_id' => session_id,
            'status' => 'created'
          }
        end

        def last_test_executed(run_id)
          results = run_results(run_id)
          results.sort_by { |r| r['updated_at'] }.reverse.find { |result| result['test_id'].present? }
        end

        def run_results(run_id)
          response = get("api/test_runs/#{run_id}/results", nil, content_type: 'application/json')
          handle_web_api_error(response, :test_run_results) if response.status != 200
          JSON.parse(response.body)
        end
      end
    end
  end
end
