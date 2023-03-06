module Inferno
  module Web
    module Controllers
      module TestRuns
        module Results
          class Index < Controller
            include Import[test_runs_repo: 'inferno.repositories.test_runs']

            def handle(req, res)
              results = test_runs_repo.results_for_test_run(req.params[:id])
              res.body = serialize(results)
            end
          end
        end
      end
    end
  end
end
