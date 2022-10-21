module Inferno
  module Web
    module Controllers
      module TestSuites
        class CheckConfiguration < Controller
          def handle(req, res)
            test_suite = repo.find(req.params[:id])
            halt 404 if test_suite.nil?

            res.body =
              Inferno::Web::Serializers::Message.render(test_suite.configuration_messages(force_recheck: true))
          end
        end
      end
    end
  end
end
