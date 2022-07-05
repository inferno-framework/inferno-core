module Inferno
  module Web
    module Controllers
      module TestSessions
        class Create < Controller
          PARAMS = [:test_suite_id, :suite_options].freeze

          def call(raw_params)
            query_params = raw_params.to_h
            body_params = JSON.parse(request.body.string).symbolize_keys
            params = query_params.merge(body_params)

            session = repo.create(create_params(params))

            repo.apply_preset(session.id, params[:preset_id]) if params[:preset_id].present?

            self.body = serialize(session)
          rescue Sequel::ValidationFailed, Sequel::ForeignKeyConstraintViolation => e
            self.body = { errors: e.message }.to_json
            self.status = 422
          rescue StandardError => e
            Application['logger'].error(e.full_message)
            self.body = { errors: e.message }.to_json
            self.status = 500
          end

          def create_params(params)
            params.slice(*PARAMS)
          end
        end
      end
    end
  end
end
