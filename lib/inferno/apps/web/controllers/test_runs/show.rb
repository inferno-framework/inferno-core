module Inferno
  module Web
    module Controllers
      module TestRuns
        class Show < Controller
          def call(params)
            test_run = repo.find(params[:id])
            halt 404 if test_run.nil?

            # TODO: add this to the swagger
            test_run.results = repo.results_for_test_run(test_run.id) if params[:include_results] == 'true'

            self.body = serialize(test_run)
          end
        end
      end
    end
  end
end
