module ONCProgram
  class StandaloneLaunch < Inferno::TestGroup
    title 'Standalone Launch with Patient Scope'
    description <<~DESCRIPTION
      # Background

      The [Standalone
      Launch](http://hl7.org/fhir/smart-app-launch/#standalone-launch-sequence)
      Sequence allows an app, like Inferno, to be launched independent of an
      existing EHR session. It is one of the two launch methods described in
      the SMART App Launch Framework alongside EHR Launch. The app will
      request authorization for the provided scope from the authorization
      endpoint, ultimately receiving an authorization token which can be used
      to gain access to resources on the FHIR server.

      # Test Methodology

      Inferno will redirect the user to the the authorization endpoint so that
      they may provide any required credentials and authorize the application.
      Upon successful authorization, Inferno will exchange the authorization
      code provided for an access token.

      For more information on the #{title}:

      * [Standalone Launch Sequence](http://hl7.org/fhir/smart-app-launch/#standalone-launch-sequence)
    DESCRIPTION

    id :standalone_launch

    input :onc_sl_client_id,
          :onc_sl_confidential_client,
          :onc_sl_client_secret,
          :onc_sl_scopes,
          :oauth_authorize_endpoint,
          :oauth_token_endpoint,
          :initiate_login_uri,
          :redirect_uris

    output :token, :id_token, :refresh_token, :patient_id

    test do
      title 'OAuth 2.0 authorize endpoint secured by transport layer security'
      description <<~DESCRIPTION
        Apps MUST assure that sensitive information (authentication secrets,
        authorization codes, tokens) is transmitted ONLY to authenticated
        servers, over TLS-secured channels. [§170.315(g)(10) Test Procedure](https://www.healthit.gov/test-method/standardized-api-patient-and-population-services)
        requires secure connection using TLS version 1.2 or higher.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/'

      run {}
    end

    test do
      title 'OAuth server redirects client browser to app redirect URI'
      description <<~DESCRIPTION
        Client browser redirected from OAuth server to redirect URI of
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
      title 'Patient-level access with OpenID Connect and Refresh Token scopes used.'
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
  end
end
