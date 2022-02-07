module ONCProgram
  class SMARTInvalidAUD < Inferno::TestGroup
    title 'SMART App Launch Error: Invalid AUD Parameter'
    description <<~DESCRIPTION
      # Background

      The Invalid AUD Sequence verifies that a SMART Launch Sequence,
      specifically the [Standalone
      Launch](http://hl7.org/fhir/smart-app-launch/#standalone-launch-sequence)
      Sequence, does not work in the case where the client sends an invalid
      FHIR server as the `aud` parameter during launch.  This must fail to ensure
      that a genuine bearer token is not leaked to a counterfit resource server.

      This test is not included as part of a regular SMART Launch Sequence
      because it requires the browser of the user to be redirected to the authorization
      service, and there is no expectation that the authorization service redirects
      the user back to Inferno with an error message.  The only requirement is that
      Inferno is not granted a code to exchange for a valid access token.  Since
      this is a special case, it is tested independently in a separate sequence.

      Note that this test will launch a new browser window.  The user is required to
      'Attest' in the Inferno user interface after the launch does not succeed,
      if the server does not return an error code.
    DESCRIPTION

    input :onc_sl_client_id,
          :onc_sl_confidential_client,
          :onc_sl_client_secret,
          :onc_sl_scopes,
          :oauth_authorize_endpoint,
          :oauth_token_endpoint,
          :initiate_login_uri,
          :redirect_uris

    id :smart_invalid_aud

    run_as_group

    test do
      title 'Inferno redirects client browser to authorization service and is redirected back to Inferno.'
      description <<~DESCRIPTION
        Client browser redirected from OAuth server to redirect URI of
        client app as described in SMART authorization sequence.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/'

      run {}
    end

    test do
      title 'Inferno client app does not receive code parameter redirect URI'
      description <<~DESCRIPTION
        Inferno redirected the user to the authorization service with an invalid AUD.
        Inferno expects that the authorization request will not succeed.  This can
        either be from the server explicitely pass an error, or stopping and the
        tester returns to Inferno to confirm that the server presented them a failure.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/'

      run {}
    end
  end
end
