module Inferno
  module Web
    module Controllers
      module TestSessions
        class Show < Controller
          def call(params)
            test_session = repo.find(params[:id])
            halt 404 if test_session.nil?

            self.body = serialize(test_session)
          end
        end
      end
    end
  end
end
