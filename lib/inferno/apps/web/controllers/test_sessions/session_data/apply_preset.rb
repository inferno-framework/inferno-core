require_relative '../../controller'

module Inferno
  module Web
    module Controllers
      module TestSessions
        module SessionData
          class ApplyPreset < Controller
            include Import[
                      test_sessions_repo: 'inferno.repositories.test_sessions',
                      presets_repo: 'inferno.repositories.presets'
                    ]

            def self.resource_class
              'SessionData'
            end

            def handle(req, res)
              test_session_id = req.params[:id]
              test_session = test_sessions_repo.find(test_session_id)

              if test_session.nil?
                Application[:logger].error("Unknown test session #{test_session_id}")
                halt 404
              end

              preset_id = req.params[:preset_id]
              preset = presets_repo.find(preset_id)

              if preset.nil?
                Application[:logger].error("Unknown preset #{preset_id}")
                halt 404
              end

              test_sessions_repo.apply_preset(test_session_id, preset_id)
              res.status = 200
            end
          end
        end
      end
    end
  end
end
