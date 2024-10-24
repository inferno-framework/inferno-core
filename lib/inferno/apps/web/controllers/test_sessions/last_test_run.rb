module Inferno
  module Web
    module Controllers
      module TestSessions
        class LastTestRun < Controller
          include Import[test_runs_repo: 'inferno.repositories.test_runs']

          def handle(req, res)
            test_run = test_runs_repo.last_test_run(req.params[:id])

            res.body =
              if test_run.nil?
                nil
              else
                Inferno::Web::Serializers::TestRun.render(test_run)
              end
          end
        end
      end
    end
  end
end
