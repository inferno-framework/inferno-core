module Inferno
  module Web
    module Controllers
      module TestRuns
        module Results
          class Index < Controller
            include Import[test_runs_repo: 'inferno.repositories.test_runs']

            def call(params)
              results = test_runs_repo.results_for_test_run(params[:test_run_id])
              self.body = serialize(results)
            end
          end
        end
      end
    end
  end
end
