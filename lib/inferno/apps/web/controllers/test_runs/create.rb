require_relative '../../../../utils/verify_runnable'
require_relative '../../../../utils/persist_inputs'

module Inferno
  module Web
    module Controllers
      module TestRuns
        class Create < Controller
          include ::Inferno::Utils::VerifyRunnable
          include ::Inferno::Utils::PersistInputs

          include Import[
                    test_sessions_repo: 'inferno.repositories.test_sessions',
                    session_data_repo: 'inferno.repositories.session_data',
                    test_runs_repo: 'inferno.repositories.test_runs'
                  ]

          PARAMS = [:test_session_id, :test_suite_id, :test_group_id, :test_id].freeze

          def handle(req, res)
            test_session = test_sessions_repo.find(req.params[:test_session_id])

            # if testsession.nil?
            if test_runs_repo.active_test_run_for_session?(test_session.id)
              halt 409, { error: 'Cannot run new test while another test run is in progress' }.to_json
            end

            verify_runnable(
              repo.build_entity(create_params(req.params)).runnable,
              req.params[:inputs],
              test_session.suite_options
            )

            test_run = repo.create(create_params(req.params).merge(status: 'queued'))

            res.body = serialize(test_run, suite_options: test_session.suite_options)

            persist_inputs(session_data_repo, req.params, test_run)

            Jobs.perform(Jobs::ExecuteTestRun, test_run.id)
          rescue Sequel::ValidationFailed, Sequel::ForeignKeyConstraintViolation,
                 Inferno::Exceptions::RequiredInputsNotFound,
                 Inferno::Exceptions::NotUserRunnableException => e
            halt 422, { errors: e.message }.to_json
          rescue StandardError => e
            Application['logger'].error(e.full_message)
            halt 500, { errors: e.message }.to_json
          end

          def create_params(params)
            params.to_h.slice(*PARAMS)
          end
        end
      end
    end
  end
end
