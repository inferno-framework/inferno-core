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

            def call(params)
              self.body = serialize(session_data_repo.get_all_from_session(params[:test_session_id]))
            end
          end
        end
      end
    end
  end
end
