module Inferno
  module Web
    module Controllers
      module TestSuites
        class Show < Controller
          def call(params)
            test_suite = repo.find(params[:id])
            halt 404 if test_suite.nil?

            self.body = serialize(test_suite, view: :full)
          end
        end
      end
    end
  end
end
