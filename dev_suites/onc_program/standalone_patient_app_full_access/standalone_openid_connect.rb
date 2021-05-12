module ONCProgram
  class StandaloneOpenIDConnect < Inferno::TestGroup
    title 'OpenID Connect'
    description <<~DESCRIPTION
      # Background

      OpenID Connect (OIDC) provides the ability to verify the identity of the
      authorizing user. Within the [SMART App Launch
      Framework](http://hl7.org/fhir/smart-app-launch/), Applications can
      request an `id_token` be provided with by including the `openid
      fhirUser` scopes when requesting authorization.

      # Test Methodology

      This sequence validates the id token returned as part of the OAuth 2.0
      token response. Once the token is decoded, the server's OIDC
      configuration is retrieved from its well-known configuration endpoint.
      This configuration is checked to ensure that all required fields are
      present. Next the keys used to cryptographically sign the id token are
      retrieved from the url contained in the OIDC configuration. Then the
      header, payload, and signature of the id token are validated. Finally,
      the FHIR resource from the `fhirUser` claim in the id token is fetched
      from the FHIR server.

      For more information see:

      * [SMART App Launch Framework](http://hl7.org/fhir/smart-app-launch/)
      * [Scopes for requesting identity data](http://hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#scopes-for-requesting-identity-data)
      * [Apps Requesting Authorization](http://hl7.org/fhir/smart-app-launch/#step-1-app-asks-for-authorization)
      * [OpenID Connect Core](https://openid.net/specs/openid-connect-core-1_0.html)
    DESCRIPTION

    id :standalone_openid_connect

    input :id_token, :onc_sl_client_id

    output :oauth_introspection_endpoint

    test do
      title 'ID token can be decoded'
      description <<~DESCRIPTION
        Verify that the ID token is a properly constructed JWT.
      DESCRIPTION
      # link 'https://tools.ietf.org/html/rfc7519'

      run {}
    end

    test do
      title 'OpenID Connect well-known configuration can be retrieved'
      description <<~DESCRIPTION
        Verify that the OpenId Connect configuration can be retrieved as
        described in the OpenID Connect Discovery 1.0 documentation
      DESCRIPTION
      # link 'https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderConfig'

      run {}
    end

    test do
      title 'OpenID Connect well-known configuration contains all required fields'
      description <<~DESCRIPTION
        Verify that the OpenId Connect configuration contains the following
        required fields: `issuer`, `authorization_endpoint`,
        `token_endpoint`, `jwks_uri`, `response_types_supported`,
        `subject_types_supported`, and
        `id_token_signing_alg_values_supported`.

        Additionally, the [SMART App Launch
        Framework](http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#scopes-for-requesting-identity-data)
        requires that the RSA SHA-256 signing algorithm be supported.
      DESCRIPTION
      # link 'https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderMetadata'

      run {}
    end

    test do
      title 'JWKS can be retrieved'
      description <<~DESCRIPTION
        Verify that the JWKS can be retrieved from the `jwks_uri` from the
        OpenID Connect well-known configuration.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#steps-for-using-an-id-token'

      run {}
    end

    test do
      title 'ID token header contains required information'
      description <<~DESCRIPTION
        Verify that the id token is signed using RSA SHA-256 [as required by
        the SMART app launch
        framework](http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#scopes-for-requesting-identity-data)
        and that the key used to sign the token can be identified in the
        JWKS.
      DESCRIPTION
      # link 'https://openid.net/specs/openid-connect-core-1_0.html#IDToken'

      run {}
    end

    test do
      title 'ID token payload has required claims and a valid signature'
      description <<~DESCRIPTION
        The `iss`, `sub`, `aud`, `exp`, and `iat` claims are required.
        Additionally:

        - `iss` must match the `issuer` from the OpenID Connect well-known
          configuration
        - `aud` must match the client ID
        - `exp` must represent a time in the future
      DESCRIPTION
      # link 'https://openid.net/specs/openid-connect-core-1_0.html#IDTokenValidation'

      run {}
    end

    test do
      title 'FHIR resource representing the current user can be retrieved'
      description <<~DESCRIPTION
        Verify that the `fhirUser` claim is present in the ID token and that
        the FHIR resource it refers to can be retrieved. The `fhirUser`
        claim must be the url for a Patient, Practitioner, RelatedPerson, or
        Person resource
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#scopes-for-requesting-identity-data'

      run {}
    end
  end
end
