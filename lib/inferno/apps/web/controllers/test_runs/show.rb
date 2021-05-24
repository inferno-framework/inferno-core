module Inferno
  module Web
    module Controllers
      module TestRuns
        class Show < Controller
          def call(params)
            test_run = repo.find(params[:id])
            halt 404 if test_run.nil?

            self.body = serialize(test_run)
          end
        end
      end
    end
  end
end
