module Inferno
  module DSL
    # The JWKS class provides methods to handle JSON Web Key Sets (JWKS)
    # within the Inferno.
    #
    # This class allows users to fetch, parse, and manage JWKS, ensuring
    # that the necessary keys for verifying tokens are available.
    class JWKS
      class << self
        # Returns a formatted JSON string of the JWKS public keys that are used for verification.
        # This method filters out keys that do not have the 'verify' operation.
        #
        # @return [String] The formatted JSON string of the JWKS public keys.
        #
        # @example
        #   jwks_json = Inferno::JWKS.jwks_json
        #   puts jwks_json
        def jwks_json
          @jwks_json ||=
            JSON.pretty_generate(
              { keys: jwks.export[:keys].select { |key| key[:key_ops]&.include?('verify') } }
            )
        end

        # Provides the default file path to the JWKS file.
        # This method is primarily used internally to locate the default JWKS file.
        #
        # @return [String] The default JWKS file path.
        #
        # @private
        def default_jwks_path
          @default_jwks_path ||= File.join(__dir__, 'jwks.json')
        end

        # Fetches the JWKS file path from the environment variable `INFERNO_JWKS_PATH`.
        # If the environment variable is not set, it falls back to the default path
        # provided by `.default_jwks_path`.
        #
        # @return [String] The JWKS file path.
        #
        # @private
        def jwks_path
          @jwks_path ||=
            ENV.fetch('INFERNO_JWKS_PATH', default_jwks_path)
        end

        # Parses and returns a `JWT::JWK::Set` object from the provided JWKS string
        # or from the file located at the JWKS path. If a user-provided JWKS string
        # is not available, it reads the JWKS from the file.
        #
        # @param user_jwks [String, nil] An optional json containing the JWKS.
        #   If not provided, the method reads from the file.
        # @return [JWT::JWK::Set] The parsed JWKS set.
        #
        # @example
        #   # Using a user-provided JWKS string
        #   user_jwks = '{"keys":[...]}'
        #   jwks_set = Inferno::JWKS.jwks(user_jwks: user_jwks)
        #
        #   # Using the default JWKS file
        #   jwks_set = Inferno::JWKS.jwks
        def jwks(user_jwks: nil)
          JWT::JWK::Set.new(JSON.parse(user_jwks.present? ? user_jwks : File.read(jwks_path)))
        end
      end
    end
  end

  JWKS = DSL::JWKS
end
