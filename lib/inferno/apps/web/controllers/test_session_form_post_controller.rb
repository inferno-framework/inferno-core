module Inferno
  module Web
    module Controllers
      class TestSessionFormPostController < Hanami::Action
        def self.call(...)
          new.call(...)
        end

        def handle(req, res)
          test_suite_id = req.params[:test_suite_id]

          test_suite = Inferno::Repositories::TestSuites.new.find(test_suite_id)
          halt 404, "Unable to find test suite with id #{test_suite_id}" if test_suite.nil?

          params = { test_suite_id: }
          suite_option_keys = test_suite.suite_options.map(&:id)
          options = req.params.to_h.slice(*suite_option_keys)

          params[:suite_options] = options.map { |key, value| { id: key, value: } } if options.present?

          repo = Inferno::Repositories::TestSessions.new
          session = repo.create(params)

          preset_id = req.params[:preset_id]

          if preset_id.present?
            preset = Inferno::Repositories::Presets.new.find(preset_id)

            halt 422, "Unable to find preset with id #{preset_id} for test suite #{test_suite_id}" if preset.nil?

            repo.apply_preset(session, preset_id)
          end

          res.redirect_to "#{Inferno::Application['base_url']}/#{test_suite_id}/#{session.id}"
        end
      end
    end
  end
end
