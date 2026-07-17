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
            test_results = run_results(run_id).select { |result| result['test_id'].present? }
            session_status['completed_test_count'] = test_results.size

            last_test_executed = last_test_executed(test_results, session_status['status'])
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

        # Serialized updated_at values can collide when results are written in
        # quick succession, so when the run is waiting, identify the waiting
        # test by its 'wait' result rather than by timestamp order alone.
        def last_test_executed(test_results, run_status)
          if run_status == 'waiting'
            wait_results = test_results.select { |result| result['result'] == 'wait' }
            test_results = wait_results if wait_results.any?
          end

          most_recent_result(test_results)
        end

        # updated_at ties are broken by array position (later results win)
        # since the API returns results in insertion order.
        def most_recent_result(results)
          results.each_with_index.max_by { |result, index| [result['updated_at'].to_s, index] }&.first
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
