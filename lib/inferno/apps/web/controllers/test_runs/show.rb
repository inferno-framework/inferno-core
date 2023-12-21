require_relative '../../serializers/test_run'

module Inferno
  module Web
    module Controllers
      module TestRuns
        class Show < Controller
          include Import[test_sessions_repo: 'inferno.repositories.test_sessions']

          def handle(req, res)
            test_run = repo.find(req.params[:id])
            halt 404 if test_run.nil?

            if req.params[:include_results] == 'true'
              results_repo = Inferno::Repositories::Results.new
              test_run.results =
                if req.params[:after].present?
                  results_repo.test_run_results_after(test_run_id: test_run.id, after: Time.parse(req.params[:after]))
                else
                  repo.results_for_test_run(test_run.id)
                end
            end
            
            ## XXX
            # binding.pry

            test_session = test_sessions_repo.find(test_run.test_session_id)
            res.body = serialize(test_run, suite_options: test_session.suite_options)
          end
        end
      end
    end
  end
end
