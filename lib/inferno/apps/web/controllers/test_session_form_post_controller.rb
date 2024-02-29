module Inferno
  module Web
    module Controllers
      class TestSessionFormPostController < Hanami::Action
        PARAMS = [:test_suite_id, :suite_options].freeze

        def self.call(...)
          new.call(...)
        end

        def handle(req, res)
          test_suite_id = req.params[:test_suite_id]

          test_suite = Inferno::Repositories::TestSuites.new.find(test_suite_id)
          halt 404 if test_suite.nil?

          params = { test_suite_id: }
          suite_option_keys = test_suite.suite_options.map(&:id)
          options = req.params.to_h.slice(*suite_option_keys)

          params[:suite_options] = options.map { |key, value| { id: key, value: } } if options.present?

          repo = Inferno::Repositories::TestSessions.new
          session = repo.create(params)

          repo.apply_preset(session, req.params[:preset_id]) if req.params[:preset_id].present?

          res.redirect_to "#{Inferno::Application['base_url']}/#{test_suite_id}/#{session.id}"
        end
      end
    end
  end
end
