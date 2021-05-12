module ONCProgram
  class EHRTokenRefresh < Inferno::TestGroup
    title 'Token Refresh'
    description <<~DESCRIPTION
      # Background

      The #{title} Sequence tests the ability of the system to successfuly exchange a refresh token for an access token.
      Refresh tokens are typically longer lived than access tokens and allow client applications to obtain a new access token
      Refresh tokens themselves cannot provide access to resources on the server.

      Token refreshes are accomplished through a `POST` request to the token exchange endpoint as described in the
      [SMART App Launch Framework](http://www.hl7.org/fhir/smart-app-launch/#step-5-later-app-uses-a-refresh-token-to-obtain-a-new-access-token)

      # Test Methodology

      This test attempts to exchange the refresh token for a new access token and verify that the information returned
      contains the required fields and uses the proper headers.

      For more information see:

      * [The OAuth 2.0 Authorization Framework](https://tools.ietf.org/html/rfc6749)
      * [Using a refresh token to obtain a new access token](http://hl7.org/fhir/smart-app-launch/#step-5-later-app-uses-a-refresh-token-to-obtain-a-new-access-token)
    DESCRIPTION

    id :ehr_token_refresh

    input :ehr_url, :client_id, :confidential_client, :client_secret, :refresh_token, :oauth_token_endpoint
    output :token

    test do
      title 'Refresh token exchange fails when supplied invalid Refresh Token'
      description <<~DESCRIPTION
        If the request failed verification or is invalid, the authorization server returns an error response.
      DESCRIPTION
      # link 'https://tools.ietf.org/html/rfc6749'

      run {}
    end

    test do
      title 'Refresh token exchange fails when supplied invalid Client ID'
      description <<~DESCRIPTION
        If the request failed verification or is invalid, the authorization server returns an error response.
      DESCRIPTION
      # link 'https://tools.ietf.org/html/rfc6749'

      run {}
    end

    test do
      title 'Refresh token exchange succeeds when optional scope parameter omitted'
      description <<~DESCRIPTION
        Server successfully exchanges refresh token at OAuth token endpoint without providing scope in
        the body of the request.

        The EHR authorization server SHALL return a JSON structure that includes an access token or a message indicating that the authorization request has been denied.
        access_token, expires_in, token_type, and scope are required. access_token must be Bearer.

        Although not required in the token refresh portion of the SMART App Launch Guide,
        the token refresh response should include the HTTP Cache-Control response header field with a value of no-store, as well as the Pragma response header field with a value of no-cache
        to be consistent with the requirements of the inital access token exchange.

        [`scopes` returned must be a strict subset of the scopes granted in the original launch](http://www.hl7.org/fhir/smart-app-launch/index.html#step-5-later-app-uses-a-refresh-token-to-obtain-a-new-access-token)
      DESCRIPTION
      # link 'https://tools.ietf.org/html/rfc6749'

      run {}
    end

    test do
      title 'Refresh token exchange succeeds when optional scope parameter provided'
      description <<~DESCRIPTION
        Server successfully exchanges refresh token at OAuth token endpoint while providing scope in
        the body of the request.

        The EHR authorization server SHALL return a JSON structure that includes an access token or a message indicating that the authorization request has been denied.
        access_token, token_type, and scope are required. access_token must be Bearer.

        Although not required in the token refresh portion of the SMART App Launch Guide,
        the token refresh response should include the HTTP Cache-Control response header field with a value of no-store, as well as the Pragma response header field with a value of no-cache
        to be consistent with the requirements of the inital access token exchange.

        [`scopes` returned must be a strict subset of the scopes granted in the original launch](http://www.hl7.org/fhir/smart-app-launch/index.html#step-5-later-app-uses-a-refresh-token-to-obtain-a-new-access-token)
      DESCRIPTION
      # link 'https://tools.ietf.org/html/rfc6749'

      run {}
    end
  end
end
