module Inferno
  module Web
    module Controllers
      module TestRuns
        class Destroy < Controller
          include Import[
                    test_runs_repo: 'inferno.repositories.test_runs',
                    results_repo: 'inferno.repositories.results'
                  ]

          def call(params)
            test_run = test_runs_repo.find(params[:id])

            if test_run.nil? || ['done', 'cancelling'].include?(test_run.status)
              # If it doesn't exist, already finished, or currently being cancelled
              self.status = 204
              return
            end

            test_run_is_waiting = (test_run.status == 'waiting')
            test_runs_repo.mark_as_cancelling(params[:id])

            if test_run_is_waiting
              waiting_result = results_repo.find_waiting_result(test_run_id: test_run.id)
              results_repo.cancel_waiting_result(waiting_result.id, 'Test cancelled by user')
              Jobs.perform(Jobs::ResumeTestRun, test_run.id)
            end

            self.status = 204
          rescue StandardError => e
            Application['logger'].error(e.full_message)
            self.body = { errors: e.message }.to_json
            self.status = 500
          end
        end
      end
    end
  end
end
