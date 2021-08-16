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
      input :url,
            title: 'FHIR Endpoint',
            description: 'URL of the FHIR endpoint used by SMART applications',
            default: 'https://inferno.healthit.gov/reference-server/r4'
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

    test do
      title 'Conformance/CapabilityStatement provides OAuth 2.0 endpoints'
      description %(
        If a server requires SMART on FHIR authorization for access, its
        metadata must support automated discovery of OAuth2 endpoints.
      )
      input :url
      output :capability_authorization_url,
             :capability_introspection_url,
             :capability_management_url,
             :capability_registration_url,
             :capability_revocation_url,
             :capability_token_url

      fhir_client do
        url :url
      end

      run do
        fhir_get_capability_statement

        assert_response_status(200)

        smart_extension =
          resource
            .rest
            &.map(&:security)
            &.find do |security|
            security.service&.any? do |service|
              service.coding&.any? do |coding|
                coding.code == 'SMART-on-FHIR'
              end
            end
          end
            &.extension
            &.find do |extension|
              extension.url == 'http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris'
            end

        assert smart_extension.present?, 'No SMART extensions found in CapabilityStatement'

        oauth_extension_urls = ['authorize', 'introspect', 'manage', 'register', 'revoke', 'token']

        oauth_urls = oauth_extension_urls.each_with_object({}) do |url, urls|
          urls[url] = smart_extension.extension.find { |extension| extension.url == url }&.valueUri
        end

        output capability_authorization_url: oauth_urls['authorize'],
               capability_introspection_url: oauth_urls['introspect'],
               capability_management_url: oauth_urls['manage'],
               capability_registration_url: oauth_urls['register'],
               capability_revocation_url: oauth_urls['revoke'],
               capability_token_url: oauth_urls['token']

        assert oauth_urls['authorize'].present?, 'No `authorize` extension found'
        assert oauth_urls['token'].present?, 'No `token` extension found'
      end
    end

    test do
      title 'OAuth 2.0 Endpoints in the conformance statement match those from the well-known configuration'
      description %(
        The server SHALL convey the FHIR OAuth authorization endpoints that are listed
        in the table below to app developers. The server SHALL use both a FHIR
        CapabilityStatement and A Well-Known Uris JSON file.
      )
      input :well_known_authorization_url,
            :well_known_introspection_url,
            :well_known_management_url,
            :well_known_registration_url,
            :well_known_revocation_url,
            :well_known_token_url,
            :capability_authorization_url,
            :capability_introspection_url,
            :capability_management_url,
            :capability_registration_url,
            :capability_revocation_url,
            :capability_token_url
      output :smart_authorization_url,
             :smart_introspection_url,
             :smart_management_url,
             :smart_registration_url,
             :smart_revocation_url,
             :smart_token_url

      run do
        mismatched_urls = []
        ['authorization', 'token', 'introspection', 'management', 'registration', 'revocation'].each do |type|
          well_known_url = send("well_known_#{type}_url")
          capability_url = send("capability_#{type}_url")

          output "smart_#{type}_url": well_known_url.presence || capability_url.presence

          mismatched_urls << type if well_known_url != capability_url
        end

        pass_if mismatched_urls.empty?

        error_message = 'The following urls do not match:'

        mismatched_urls.each do |type|
          well_known_url = send("well_known_#{type}_url")
          capability_url = send("capability_#{type}_url")

          error_message += "\n- #{type.capitalize}:"
          error_message += "\n  - Well-Known: #{well_known_url}\n  - CapabilityStatement: #{capability_url}"
        end

        assert false, error_message
      end
    end
  end
end
