module Inferno
  module Web
    module Controllers
      module TestSessions
        class LastTestRun < Controller
          include Import[test_runs_repo: 'repositories.test_runs']

          def call(params)
            test_run = test_runs_repo.last_test_run(params[:test_session_id])

            self.body =
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
