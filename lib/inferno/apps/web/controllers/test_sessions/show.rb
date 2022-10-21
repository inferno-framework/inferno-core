module Inferno
  module Web
    module Controllers
      module TestSessions
        class Show < Controller
          def handle(req, res)
            test_session = repo.find(req.params[:id])
            halt 404 if test_session.nil?

            res.body = serialize(test_session)
          end
        end
      end
    end
  end
end
