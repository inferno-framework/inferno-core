module Inferno
  module DSL
    class JWKS
      class << self
        def jwks_json
          @jwks_json ||=
            JSON.pretty_generate(
              { keys: jwks.export[:keys].select { |key| key[:key_ops]&.include?('verify') } }
            )
        end

        def default_jwks_path
          @default_jwks_path ||= File.join(__dir__, 'jwks.json')
        end

        def jwks_path
          @jwks_path ||=
            ENV.fetch('CORE_JWKS_PATH', default_jwks_path)
        end

        def jwks(user_jwks: nil)
          @jwks ||= JWT::JWK::Set.new(JSON.parse(user_jwks.present? ? user_jwks : File.read(jwks_path)))
        end
      end
    end
  end
end
