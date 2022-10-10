module Inferno
  module Web
    module Controllers
      module TestRuns
        class Show < Controller
          include Import[test_sessions_repo: 'inferno.repositories.test_sessions']

          def call(params)
            test_run = repo.find(params[:id])
            halt 404 if test_run.nil?

            if params[:include_results] == 'true'
              results_repo = Inferno::Repositories::Results.new
              test_run.results =
                if params[:after].present?
                  results_repo.test_run_results_after(test_run_id: test_run.id, after: Time.parse(params[:after]))
                else
                  repo.results_for_test_run(test_run.id)
                end
            end

            test_session = test_sessions_repo.find(test_run.test_session_id)
            self.body = serialize(test_run, suite_options: test_session.suite_options)
          end
        end
      end
    end
  end
end
