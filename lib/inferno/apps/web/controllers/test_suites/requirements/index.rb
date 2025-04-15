module Inferno
  module Web
    module Controllers
      module TestSuites
        module Requirements
          class Index < Controller
            include Import[test_suites_repo: 'inferno.repositories.test_suites']
            include Import[test_sessions_repo: 'inferno.repositories.test_sessions']

            def handle(req, res)
              test_suite = test_suites_repo.find(req.params[:id])
              halt 404, "Test Suite `#{req.params[:id]}` not found" if test_suite.nil?

              test_session = nil
              if req.params[:session_id]
                test_session = test_sessions_repo.find(req.params[:session_id])
                halt 404, "Test session `#{req.params[:session_id]}` not found" if test_session.nil?
              end

              requirements = repo.requirements_for_suite(test_suite.id, test_session&.id)

              res.body = serialize(requirements)
            end
          end
        end
      end
    end
  end
end
