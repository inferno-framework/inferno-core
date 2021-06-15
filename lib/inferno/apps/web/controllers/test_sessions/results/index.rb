module Inferno
  module Web
    module Controllers
      module TestSessions
        module Results
          class Index < Controller
            include Import[test_sessions_repo: 'repositories.test_sessions']

            def call(params)
              self.body = serialize(test_sessions_repo.results_for_test_session(params[:test_session_id]))
            end
          end
        end
      end
    end
  end
end
