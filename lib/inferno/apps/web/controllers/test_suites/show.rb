module Inferno
  module Web
    module Controllers
      module TestSuites
        class Show < Controller
          def handle(req, res)
            test_suite = repo.find(req.params[:id])
            halt 404 if test_suite.nil?

            res.body = serialize(test_suite, view: :full)
          end
        end
      end
    end
  end
end
