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
              test_session = test_sessions_repo.find(req.params[:session_id])
              halt 404 if test_suite.nil? || test_session.nil?

              requirement_ids = test_suite.suite_requirements(test_session.suite_options)
              requirements = repo.filter_requirements_by_ids(requirement_ids)

              res.body = serialize(requirements)
            end
          end
        end
      end
    end
  end
end
