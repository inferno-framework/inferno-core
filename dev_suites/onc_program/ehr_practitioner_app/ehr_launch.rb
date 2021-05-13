module ONCProgram
  class EHRLaunch < Inferno::TestGroup
    title 'EHR Launch with Practitioner Scope'
    description <<~DESCRIPTION
      # Background

      The [EHR
      Launch](http://hl7.org/fhir/smart-app-launch/index.html#ehr-launch-sequence)
      is one of two ways in which an app can be launched, the other being
      Standalone launch. In an EHR launch, the app is launched from an
      existing EHR session or portal by a redirect to the registered launch
      URL. The EHR provides the app two parameters:

      * `iss` - Which contains the FHIR server url
      * `launch` - An identifier needed for authorization

      # Test Methodology

      Inferno will wait for the EHR server redirect upon execution. When the
      redirect is received Inferno will check for the presence of the `iss`
      and `launch` parameters. The security of the authorization endpoint is
      then checked and authorization is attempted using the provided `launch`
      identifier.

      For more information on the #{title} see:

      * [SMART EHR Launch Sequence](http://hl7.org/fhir/smart-app-launch/index.html#ehr-launch-sequence)
    DESCRIPTION

    id :ehr_launch

    input :enc_ehr_url,
          :onc_ehr_client_id,
          :onc_ehr_confidential_client,
          :onc_ehr_client_secret,
          :onc_ehr_scopes,
          :oauth_authorize_endpoint,
          :oauth_token_endpoint,
          :initiate_login_uri,
          :redirect_uris

    output :token, :id_token, :refresh_token, :patient_id

    test do
      title 'EHR server redirects client browser to Inferno app launch URI'
      description <<~DESCRIPTION
        Client browser sent from EHR server to app launch URI of client app
        as described in SMART EHR Launch Sequence.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/'

      run {}
    end

    test do
      title 'EHR provides iss and launch parameter to the Inferno app launch URI via the client browser querystring'
      description <<~DESCRIPTION
        The EHR is required to provide a reference to the EHR FHIR endpoint
        in the iss queystring parameter, and an opaque identifier for the
        launch in the launch querystring parameter.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/'

      run {}
    end

    test do
      title 'OAuth 2.0 server redirects client browser to Inferno app redirect URI'
      description <<~DESCRIPTION
        Client browser redirected from OAuth 2.0 server to redirect URI of
        client app as described in SMART authorization sequence.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/'

      run {}
    end

    test do
      title 'Inferno client app receives code parameter and correct state parameter from OAuth server at redirect URI'
      description <<~DESCRIPTION
        Code and state are required querystring parameters. State must be
        the exact value received from the client.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/'

      run {}
    end

    test do
      title 'OAuth token exchange endpoint secured by transport layer security'
      description <<~DESCRIPTION
        Apps MUST assure that sensitive information (authentication secrets,
        authorization codes, tokens) is transmitted ONLY to authenticated
        servers, over TLS-secured channels.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/'

      run {}
    end

    test do
      title 'OAuth token exchange fails when supplied invalid code'
      description <<~DESCRIPTION
        If the request failed verification or is invalid, the authorization
        server returns an error response.
      DESCRIPTION
      # link 'https://tools.ietf.org/html/rfc6749'

      run {}
    end

    test do
      title 'OAuth token exchange fails when supplied invalid client ID'
      description <<~DESCRIPTION
        If the request failed verification or is invalid, the authorization
        server returns an error response.
      DESCRIPTION
      # link 'https://tools.ietf.org/html/rfc6749'

      run {}
    end

    test do
      title 'OAuth token exchange request succeeds when supplied correct information'
      description <<~DESCRIPTION
        After obtaining an authorization code, the app trades the code for
        an access token via HTTP POST to the EHR authorization server's
        token endpoint URL, using content-type
        application/x-www-form-urlencoded, as described in section [4.1.3 of
        RFC6749](https://tools.ietf.org/html/rfc6749#section-4.1.3).
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/'

      run {}
    end

    test do
      title 'OAuth token exchange response body contains required information encoded in JSON'
      description <<~DESCRIPTION
        The EHR authorization server shall return a JSON structure that
        includes an access token or a message indicating that the
        authorization request has been denied.
        `access_token`, `token_type`, and `scope` are required. `token_type` must
        be Bearer. `expires_in` is required for token refreshes.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/'

      run {}
    end

    test do
      title 'OAuth token exchange response includes correct HTTP Cache-Control and Pragma headers'
      description <<~DESCRIPTION
        The authorization servers response must include the HTTP
        Cache-Control response header field with a value of no-store, as
        well as the Pragma response header field with a value of no-cache.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/'

      run {}
    end

    test do
      title 'User-level access with OpenID Connect and Refresh Token scopes used.'
      description <<~DESCRIPTION
        The scopes being input must follow the guidelines specified in the smart-app-launch guide.
        All scopes requested are expected to be granted.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#quick-start'

      run {}
    end

    test do
      title 'Server rejects unauthorized access'
      description <<~DESCRIPTION
        A server SHALL reject any unauthorized requests by returning an HTTP
        401 unauthorized response code.
      DESCRIPTION
      # link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html#behavior'

      run {}
    end

    test do
      title 'Launch context contains smart_style_url which links to valid JSON'
      description <<~DESCRIPTION
        In order to mimic the style of the SMART host more closely, SMART
        apps can check for the existence of this launch context parameter
        and download the JSON file referenced by the URL value.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#styling'

      run {}
    end

    test do
      title 'Launch context contains need_patient_banner'
      description <<~DESCRIPTION
        `need_patient_banner` is a boolean value indicating whether the app
        was launched in a UX context where a patient banner is required
        (when true) or not required (when false).
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#launch-context-arrives-with-your-access_token'

      run {}
    end
  end
end
