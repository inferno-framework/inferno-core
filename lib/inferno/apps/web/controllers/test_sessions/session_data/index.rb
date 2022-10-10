require_relative '../../../serializers/session_data'

module Inferno
  module Web
    module Controllers
      module TestSessions
        module SessionData
          class Index < Controller
            include Import[session_data_repo: 'inferno.repositories.session_data']

            def self.resource_class
              'SessionData'
            end

            def handle(req, res)
              res.body = serialize(session_data_repo.get_all_from_session(req.params[:test_session_id]))
            end
          end
        end
      end
    end
  end
end
