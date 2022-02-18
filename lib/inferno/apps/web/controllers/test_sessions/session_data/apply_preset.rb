module Inferno
  module Web
    module Controllers
      module TestSessions
        module SessionData
          class ApplyPreset < Controller
            include Import[
                      test_sessions_repo: 'repositories.test_sessions',
                      presets_repo: 'repositories.presets'
                    ]

            def self.resource_class
              'SessionData'
            end

            def call(params)
              test_session_id = params[:test_session_id]
              test_session = test_sessions_repo.find(test_session_id)

              if test_session.nil?
                Application[:logger].error("Unknown test session #{test_session_id}")
                self.status = 404
                return
              end

              preset_id = params[:preset_id]
              preset = presets_repo.find(preset_id)

              if preset.nil?
                Application[:logger].error("Unknown preset #{preset_id}")
                self.status = 404
                return
              end

              test_sessions_repo.apply_preset(test_session_id, preset_id)
              self.status = 200
            end
          end
        end
      end
    end
  end
end
