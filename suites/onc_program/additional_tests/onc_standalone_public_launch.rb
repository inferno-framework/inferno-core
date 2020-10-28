module ONCProgram
  class ONCStandalonePublicLaunch < Inferno::TestGroup
    title 'Public Client Standalone Launch with OpenID Connect'
    description <<~DESCRIPTION
      Register Inferno as a public client with patient access and execute standalone launch.
    DESCRIPTION

    id :onc_standalone_public_launch

    input :onc_public_client_id,
          :onc_public_scopes,
          :onc_sl_oauth_authorize_endpoint,
          :onc_sl_oauth_token_endpoint,
          :initiate_login_uri,
          :redirect_uris

    output :token, :id_token, :refresh_token, :patient_id

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
      title 'OAuth token exchange response body contains patient context and patient resource can be retrieved'
      description <<~DESCRIPTION
        The `patient` field is a String value with a patient id,
        indicating that the app was launched in the context of this FHIR
        Patient
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html#scopes-for-requesting-context-data'

      run {}
    end

    test do
      title 'OAuth token exchange response contains OpenID Connect id_token'
      description <<~DESCRIPTION
        This test requires that an OpenID Connect id_token is provided to demonstrate authentication capabilies
        for public clients.
      DESCRIPTION
      # link 'http://hl7.org/fhir/smart-app-launch/'

      run {}
    end
  end
end
