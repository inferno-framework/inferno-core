module Inferno
  module Web
    module Controllers
      module TestSessions
        module Results
          class IoValue < Controller
            include Import[
              test_sessions_repo: 'inferno.repositories.test_sessions',
              results_repo: 'inferno.repositories.results'
            ]

            def handle(req, res)
              test_session_id = req.params[:id]
              result_id = req.params[:result_id]
              type = req.params[:type]
              name = req.params[:name]

              unless %w[inputs outputs].include?(type)
                res.status = 400
                res.body = { error: 'Invalid I/O type. Must be "inputs" or "outputs".' }.to_json
                return
              end

              test_session_results = results_repo.current_results_for_test_session(test_session_id)
              result = test_session_results.find { |r| r.id == result_id }

              if result.nil?
                res.status = 404
                res.body = { error: "Result '#{result_id}' not found for test session '#{test_session_id}'." }.to_json
                return
              end

              entry = result_io_by_name(result, type, name)
              value = entry&.dig('value')

              if value.blank?
                res.status = 404
                res.body = { error: "#{type.singularize.capitalize} '#{name}' not found or missing value." }.to_json
                return
              end

              res.body = value.is_a?(Hash) ? value.to_json : value
              res.content_type = content_type_for(value)
            end

            private

            def result_io_by_name(result, io_type, name)
              result.public_send(io_type)
                .find { |item| item['name'] == name }
            end

            def content_type_for(value)
              return 'application/json' if value.is_a?(Hash)

              trimmed = value&.strip

              return 'application/json' if trimmed&.start_with?('{', '[')
              return 'application/xml' if trimmed&.start_with?('<') && trimmed.end_with?('>')

              'text/plain'
            end
          end
        end
      end
    end
  end
end
