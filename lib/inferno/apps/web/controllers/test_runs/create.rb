module Inferno
  module Web
    module Controllers
      module TestRuns
        class Create < Controller
          include Import[
                    test_sessions_repo: 'repositories.test_sessions',
                    session_data_repo: 'repositories.session_data'
                  ]

          PARAMS = [:test_session_id, :test_suite_id, :test_group_id, :test_id].freeze

          def call(params)
            test_session = test_sessions_repo.find(params[:test_session_id])

            # if testsession.nil?

            test_run = repo.create(create_params(params).merge(status: 'queued'))
            required_inputs = test_run.runnable.contained_required_inputs.map(&:to_s)

            missing_inputs = required_inputs - params[:inputs].map { |input| input[:name] }
            raise Inferno::Exceptions::RequiredInputsNotFound, missing_inputs if missing_inputs.any?

            self.body = serialize(test_run)

            params[:inputs]&.each do |input|
              session_data_repo.save(
                test_session_id: test_session.id,
                name: input[:name],
                value: input[:value]
              )
            end

            Jobs.perform(Jobs::ExecuteTestRun, test_run.id)
          rescue Sequel::ValidationFailed, Sequel::ForeignKeyConstraintViolation,
                 Inferno::Exceptions::RequiredInputsNotFound => e
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
