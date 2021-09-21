require_relative 'token_payload_validation'

module SMART
  class OpenIDTokenPayloadTest < Inferno::Test
    include TokenPayloadValidation
    id :smart_openid_token_payload
    title 'ID token payload has required claims and a valid signature'
    description %(
      The `iss`, `sub`, `aud`, `exp`, and `iat` claims are required.
      Additionally:

      - `iss` must match the `issuer` from the OpenID Connect well-known
        configuration
      - `aud` must match the client ID
      - `exp` must represent a time in the future
    )

    REQUIRED_CLAIMS = ['iss', 'sub', 'aud', 'exp', 'iat'].freeze

    def required_claims
      REQUIRED_CLAIMS.dup
    end

    input :id_token,
          :openid_configuration_json,
          :id_token_jwk_json,
          :client_id

    run do
      skip_if id_token.blank?, 'No ID Token'
      skip_if openid_configuration_json.blank?, 'No OpenID Configuration found'
      skip_if id_token_jwk_json.blank?, 'No ID Token jwk found'
      skip_if client_id.blank?, 'No Client ID'

      begin
        configuration = JSON.parse(openid_configuration_json)
        jwk = JSON.parse(id_token_jwk_json).deep_symbolize_keys
        payload, =
          JWT.decode(
            id_token,
            JWT::JWK.import(jwk).public_key,
            true,
            algorithms: ['RS256'],
            exp_leeway: 60,
            iss: configuration['issuer'],
            aud: client_id,
            verify_not_before: false,
            verify_iat: false,
            verify_jti: false,
            verify_sub: false,
            verify_iss: true,
            verify_aud: true
          )
      rescue StandardError => e
        assert false, "Token validation error: #{e.message}"
      end

      missing_claims = required_claims - payload.keys
      missing_claims_string = missing_claims.map { |claim| "`#{claim}`" }.join(', ')

      assert missing_claims.empty?, "ID token missing required claims: #{missing_claims_string}"
    end
  end
end
