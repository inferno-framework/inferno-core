module Inferno
  module Web
    module Controllers
      module TestSessions
        class ClientShow < Controller
          CLIENT_PAGE =
            ERB.new(
              File.read(
                File.join(
                  Inferno::Application.root, 'lib', 'inferno', 'apps', 'web', 'templates', 'client_index.html.erb'
                )
              )
            ).result.freeze

          def handle(req, res)
            test_session_id = req.params[:id]
            test_suite_id = req.params[:test_suite_id]

            test_session = repo.find(test_session_id)
            halt 404 if test_session.nil?

            if test_suite_id.blank? || test_suite_id != test_session.test_suite_id
              test_suite_id = test_session.test_suite_id

              res.redirect_to "#{Inferno::Application['base_url']}/#{test_suite_id}/#{test_session_id}"
            end

            test_suite = Inferno::Repositories::TestSuites.new.find(test_suite_id)

            halt 404 if test_suite.nil?

            res.format = :html
            res.body = CLIENT_PAGE
          end
        end
      end
    end
  end
end
