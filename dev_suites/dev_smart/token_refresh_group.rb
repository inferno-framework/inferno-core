require_relative 'token_refresh_test'
require_relative 'token_refresh_body_test'
require_relative 'token_response_headers_test'

module SMART
  class TokenRefreshGroup < Inferno::TestGroup
    id :smart_token_refresh
    title 'SMART Token Refresh'
    description %(
      # Background

      The #{title} Sequence tests the ability of the system to successfuly
      exchange a refresh token for an access token. Refresh tokens are typically
      longer lived than access tokens and allow client applications to obtain a
      new access token Refresh tokens themselves cannot provide access to
      resources on the server.

      Token refreshes are accomplished through a `POST` request to the token
      exchange endpoint as described in the [SMART App Launch
      Framework](http://www.hl7.org/fhir/smart-app-launch/#step-5-later-app-uses-a-refresh-token-to-obtain-a-new-access-token).

      # Test Methodology

      This test attempts to exchange the refresh token for a new access token
      and verify that the information returned contains the required fields and
      uses the proper headers.

      For more information see:

      * [The OAuth 2.0 Authorization
        Framework](https://tools.ietf.org/html/rfc6749)
      * [Using a refresh token to obtain a new access
        token](http://hl7.org/fhir/smart-app-launch/#step-5-later-app-uses-a-refresh-token-to-obtain-a-new-access-token)
    )

    test from: :smart_token_refresh
    test from: :smart_token_refresh_body
    test from: :smart_token_response_headers,
         config: {
           requests: {
             token: { name: :token_refresh }
           }
         }
  end
end
