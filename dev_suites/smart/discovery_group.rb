module SMART
  class DiscoveryGroup < Inferno::TestGroup
    id :smart_discovery
    title 'SMART on FHIR Discovery'
    description %(
      # Background

      The #{title} Sequence test looks for authorization endpoints and SMART
      capabilities as described by the [SMART App Launch
      Framework](http://hl7.org/fhir/smart-app-launch/conformance/index.html).
      The SMART launch framework uses OAuth 2.0 to *authorize* apps, like
      Inferno, to access certain information on a FHIR server. The
      authorization service accessed at the endpoint allows users to give
      these apps permission without sharing their credentials with the
      application itself. Instead, the application receives an access token
      which allows it to access resources on the server. The access token
      itself has a limited lifetime and permission scopes associated with it.
      A refresh token may also be provided to the application in order to
      obtain another access token. Unlike access tokens, a refresh token is
      not shared with the resource server. If OpenID Connect is used, an id
      token may be provided as well. The id token can be used to
      *authenticate* the user. The id token is digitally signed and allows the
      identity of the user to be verified.

      # Test Methodology

      This test suite will examine the SMART on FHIR configuration contained
      in both the `/metadata` and `/.well-known/smart-configuration`
      endpoints.

      For more information see:

      * [SMART App Launch Framework](http://hl7.org/fhir/smart-app-launch/index.html)
      * [The OAuth 2.0 Authorization Framework](https://tools.ietf.org/html/rfc6749)
      * [OpenID Connect Core](https://openid.net/specs/openid-connect-core-1_0.html)
    )

    test do
      title 'FHIR server makes SMART configuration available from well-known endpoint'
      description %(
        The authorization endpoints accepted by a FHIR resource server can
        be exposed as a Well-Known Uniform Resource Identifier
      )
      input :url
      output :well_known_configuration,
             :well_known_authorization_url,
             :well_known_introspection_url,
             :well_known_management_url,
             :well_known_registration_url,
             :well_known_revocation_url,
             :well_known_token_url
      makes_request :smart_well_known_configuration

      run do
        well_known_configuration_url = "#{url.chomp('/')}/.well-known/smart-configuration"
        get(well_known_configuration_url, name: :smart_well_known_configuration)

        assert_response_status(200)

        assert_valid_json(request.response_body)

        config = JSON.parse(request.response_body)
        output well_known_configuration: request.response_body,
               well_known_authorization_url: config['authorization_endpoint'],
               well_known_introspection_url: config['introspection_endpoint'],
               well_known_management_url: config['management_endpoint'],
               well_known_registration_url: config['registration_endpoint'],
               well_known_revocation_url: config['revocation_endpoint'],
               well_known_token_url: config['token_endpoint']

        content_type = request.response_header('Content-Type')&.value

        assert content_type.present?, 'No `Content-Type` header received.'
        assert content_type.start_with?('application/json'),
               "`Content-Type` must be `application/json`, but received: `#{content_type}`"
      end
    end

    test do
      title 'Well-known configuration contains required fields'
      description %(
        The JSON from .well-known/smart-configuration contains the following
        required fields: `authorization_endpoint`, `token_endpoint`,
        `capabilities`
      )
      input :well_known_configuration

      run do
        skip_if well_known_configuration.blank?, 'No well-known configuration found'
        config = JSON.parse(well_known_configuration)

        ['authorization_endpoint', 'token_endpoint', 'capabilities'].each do |key|
          assert config.key?(key), "Well-known configuration does not include `#{key}`"
          assert config[key].present?, "Well-known configuration field `#{key}` is blank"
        end

        assert config['authorization_endpoint'].is_a?(String),
               'Well-known `authorization_endpoint` field must be a string'
        assert config['token_endpoint'].is_a?(String),
               'Well-known `token_endpoint` field must be a string'
        assert config['capabilities'].is_a?(Array),
               'Well-known `capabilities` field must be an array'

        non_string_capabilities = config['capabilities'].reject { |capability| capability.is_a? String }

        assert non_string_capabilities.blank?, %(
          Well-known `capabilities` field must be an array of strings, but found
          non-string values:
          #{non_string_capabilities.map { |value| "`#{value.nil? ? 'nil' : value}`" }.join(', ')}
        )
      end
    end
  end
end
