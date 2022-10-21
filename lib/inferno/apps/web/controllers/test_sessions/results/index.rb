module Inferno
  module Web
    module Controllers
      module TestSessions
        module Results
          class Index < Controller
            include Import[test_sessions_repo: 'inferno.repositories.test_sessions']

            def handle(req, res)
              res.body =
                if req.params[:all] == 'true'
                  serialize(test_sessions_repo.results_for_test_session(req.params[:id]))
                else
                  serialize(repo.current_results_for_test_session(req.params[:id]))
                end
            end
          end
        end
      end
    end
  end
end
