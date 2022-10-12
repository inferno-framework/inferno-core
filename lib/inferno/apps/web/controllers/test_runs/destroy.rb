module Inferno
  module Web
    module Controllers
      module TestRuns
        class Destroy < Controller
          include Import[
                    test_runs_repo: 'inferno.repositories.test_runs',
                    results_repo: 'inferno.repositories.results'
                  ]

          def handle(req, res)
            test_run = test_runs_repo.find(req.params[:id])

            if test_run.nil? || ['done', 'cancelling'].include?(test_run.status)
              # If it doesn't exist, already finished, or currently being cancelled
              halt 204
            end

            test_run_is_waiting = (test_run.status == 'waiting')
            test_runs_repo.mark_as_cancelling(req.params[:id])

            if test_run_is_waiting
              waiting_result = results_repo.find_waiting_result(test_run_id: test_run.id)
              results_repo.cancel_waiting_result(waiting_result.id, 'Test cancelled by user')
              Jobs.perform(Jobs::ResumeTestRun, test_run.id)
            end

            res.status = 204
          rescue StandardError => e
            Application['logger'].error(e.full_message)
            halt 500, { errors: e.message }.to_json
          end
        end
      end
    end
  end
end
