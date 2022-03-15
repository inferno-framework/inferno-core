module Inferno
  module Web
    module Controllers
      module TestRuns
        class Create < Controller
          include Import[
                    test_sessions_repo: 'repositories.test_sessions',
                    session_data_repo: 'repositories.session_data',
                    test_runs_repo: 'repositories.test_runs'
                  ]

          PARAMS = [:test_session_id, :test_suite_id, :test_group_id, :test_id].freeze

          def verify_runnable(runnable, inputs)
            missing_inputs = runnable&.missing_inputs(inputs)
            user_runnable = runnable&.user_runnable?
            raise Inferno::Exceptions::RequiredInputsNotFound, missing_inputs if missing_inputs&.any?
            raise Inferno::Exceptions::NotUserRunnableException unless user_runnable
          end

          def call(params)
            test_session = test_sessions_repo.find(params[:test_session_id])

            # if testsession.nil?
            if test_runs_repo.active_test_run_for_session?(test_session.id)
              self.status = 409
              self.body = { error: 'Cannot run new test while another test run is in progress' }.to_json
              return
            end

            verify_runnable(repo.build_entity(create_params(params)).runnable, params[:inputs])

            test_run = repo.create(create_params(params).merge(status: 'queued'))

            self.body = serialize(test_run)

            params[:inputs]&.each do |input|
              session_data_repo.save(
                test_session_id: test_session.id,
                name: input[:name],
                value: input[:value],
                type: input[:type]
              )
            end

            Jobs.perform(Jobs::ExecuteTestRun, test_run.id)
          rescue Sequel::ValidationFailed, Sequel::ForeignKeyConstraintViolation,
                 Inferno::Exceptions::RequiredInputsNotFound,
                 Inferno::Exceptions::NotUserRunnableException => e
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
