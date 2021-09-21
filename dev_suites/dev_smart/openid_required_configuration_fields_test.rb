module SMART
  class OpenIDRequiredConfigurationFieldsTest < Inferno::Test
    id :smart_openid_required_configuration_fields
    title 'OpenID Connect well-known configuration contains all required fields'
    description %(
      Verify that the OpenId Connect configuration contains the following
      required fields: `issuer`, `authorization_endpoint`, `token_endpoint`,
      `jwks_uri`, `response_types_supported`, `subject_types_supported`, and
      `id_token_signing_alg_values_supported`.

      Additionally, the [SMART App Launch
      Framework](http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#scopes-for-requesting-identity-data)
      requires that the RSA SHA-256 signing algorithm be supported.
    )

    input :openid_configuration_json
    output :openid_jwks_uri

    REQUIRED_FIELDS =
      [
        'issuer',
        'authorization_endpoint',
        'token_endpoint',
        'jwks_uri',
        'response_types_supported',
        'subject_types_supported',
        'id_token_signing_alg_values_supported'
      ].freeze

    def required_fields
      REQUIRED_FIELDS.dup
    end

    run do
      skip_if openid_configuration_json.blank?

      configuration = JSON.parse(openid_configuration_json)
      output openid_jwks_uri: configuration['jwks_uri']

      missing_fields = required_fields - configuration.keys
      missing_fields_string = missing_fields.map { |field| "`#{field}`" }.join(', ')

      assert missing_fields.empty?,
             "OpenID Connect well-known configuration missing required fields: #{missing_fields_string}"

      assert configuration['id_token_signing_alg_values_supported'].include?('RS256'),
             'Signing tokens with RSA SHA-256 not supported'
    end
  end
end
