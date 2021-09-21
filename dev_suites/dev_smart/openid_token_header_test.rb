module SMART
  class OpenIDTokenHeaderTest < Inferno::Test
    id :smart_openid_token_header
    title 'ID token header contains required information'
    description %(
      Verify that the id token header indicates that the tokenis signed using
      RSA SHA-256 [as required by the SMART app launch
      framework](http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#scopes-for-requesting-identity-data)
      and that the key used to sign the token can be identified in the JWKS.
    )

    input :id_token_header_json, :openid_rsa_keys_json
    output :id_token_jwk_json

    run do
      skip_if id_token_header_json.blank?
      skip_if openid_rsa_keys_json.blank?

      header = JSON.parse(id_token_header_json)
      algorithm = header['alg']

      assert algorithm == 'RS256', "ID Token signed with `#{algorithm}` rather than RS256"

      kid = header['kid']
      rsa_keys = JSON.parse(openid_rsa_keys_json)

      if rsa_keys.length > 1
        assert kid.present?, '`kid` field must be present if JWKS contains multiple keys'
        jwk = rsa_keys.find { |key| key['kid'] == kid }
        assert jwk.present?, "JWKS did not contain an RS256 key with an id of `#{kid}`"
      else
        jwk = rsa_keys.first
        assert kid.blank? || jwk['kid'] == kid, "JWKS did not contain an RS256 key with an id of `#{kid}`"
      end

      output id_token_jwk_json: jwk.to_json
    end
  end
end
