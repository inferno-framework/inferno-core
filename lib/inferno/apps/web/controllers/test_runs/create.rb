module Inferno
  module Web
    module Controllers
      module TestRuns
        class Create < Controller
          include Import[test_sessions_repo: 'repositories.test_sessions']

          PARAMS = [:test_session_id, :test_suite_id, :test_group_id, :test_id].freeze

          def call(params)
            test_session = test_sessions_repo.find(params[:test_session_id])

            test_run = repo.create(create_params(params))

            params[:inputs]&.each do |input|
              session_data_repo.save(
                test_session_id: test_session.id,
                name: input[:name],
                value: input[:value]
              )
            end

            # if testsession.nil?

            TestRunner
              .new(test_session: test_session, test_run: test_run)
              .start

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
