module Inferno
  module Web
    module Controllers
      module TestRuns
        class Create < Controller
          include Import[test_sessions_repo: 'repositories.test_sessions']

          PARAMS = [:test_session_id, :test_suite_id, :test_group_id, :test_id].freeze

          def call(params)
            test_run = repo.create(create_params(params))
            inputs = (params[:inputs] || {}).each_with_object({}) do |input, new_inputs|
              new_inputs[input[:name].to_sym] = input[:value]
            end

            test_session = test_sessions_repo.find(test_run.test_session_id)
            # if testsession.nil?

            TestRunner
              .new(test_session: test_session, test_run: test_run)
              .start(test_run.runnable, inputs)

            self.body = serialize(test_run)
          rescue Sequel::ValidationFailed, Sequel::ForeignKeyConstraintViolation => e
            self.body = { errors: e.message }.to_json
            self.status = 422
          rescue StandardError => e
            Application['logger'].error(e.full_message)
            self.body = { errors: e.message }.to_json
            self.status = 500
          end

          def create_params(params)
            params.to_h.slice(*PARAMS)
          end
        end
      end
    end
  end
end
