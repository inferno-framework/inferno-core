module SMART
  class OpenIDRetrieveJWKSTest < Inferno::Test
    id :smart_openid_retrieve_jwks
    title 'JWKS can be retrieved'
    description %(
        Verify that the JWKS can be retrieved from the `jwks_uri` from the
        OpenID Connect well-known configuration.
      )

    input :openid_jwks_uri
    output :openid_jwks_json, :openid_rsa_keys_json
    makes_request :openid_jwks

    run do
      skip_if openid_jwks_uri.blank?

      get(openid_jwks_uri, name: :openid_jwks)

      assert_response_status(200)
      assert_valid_json(response[:body])
      output openid_jwks_json: response[:body]

      raw_jwks = JSON.parse(response[:body])
      assert raw_jwks['keys'].is_a?(Array), 'JWKS `keys` field must be an array'

      # https://tools.ietf.org/html/rfc7517#section-5
      # Implementations SHOULD ignore JWKs within a JWK Set that use "kty"
      # (key type) values that are not understood by them.
      # SMART only requires support of RSA SHA-256 keys
      rsa_keys = raw_jwks['keys'].select { |jwk| jwk['kty'] == 'RSA' }

      assert rsa_keys.present?, 'JWKS contains no RSA keys'

      rsa_keys.each do |jwk|
        JWT::JWK.import(jwk.deep_symbolize_keys)
      rescue StandardError
        assert false, "Invalid JWK: #{jwk.to_json}"
      end

      output openid_rsa_keys_json: rsa_keys.to_json
    end
  end
end
