require_relative 'token_payload_validation'

module SMART
  class TokenRefreshBodyTest < Inferno::Test
    include TokenPayloadValidation

    id :smart_token_refresh_body
    title 'Server successfully refreshes the access token when optional scope parameter omitted'
    description %(
      Server successfully exchanges refresh token at OAuth token endpoint
      without providing scope in the body of the request.

      The EHR authorization server SHALL return a JSON structure that includes
      an access token or a message indicating that the authorization request
      has been denied. `access_token`, `expires_in`, `token_type`, and `scope` are
      required. `access_token` must be `Bearer`.

      Although not required in the token refresh portion of the SMART App
      Launch Guide, the token refresh response should include the HTTP
      Cache-Control response header field with a value of no-store, as well as
      the Pragma response header field with a value of no-cache to be
      consistent with the requirements of the inital access token exchange.
    )
    input :received_scopes
    output :refresh_token, :access_token, :token_retrieval_time, :expires_in, :received_scopes
    uses_request :token_refresh

    run do
      skip_if request.status != 200, 'Token exchange was unsuccessful'

      assert_valid_json(response[:body])

      body = JSON.parse(response[:body])
      output refresh_token: body['refresh_token'] if body.key? 'refresh_token'

      required_fields = ['access_token', 'token_type', 'expires_in', 'scope']
      validate_required_fields_present(body, required_fields)

      old_received_scopes = received_scopes
      output access_token: body['access_token'],
             token_retrieval_time: Time.now.iso8601,
             expires_in: body['expires_in'],
             received_scopes: body['scope']

      validate_token_field_types(body)
      validate_token_type(body)

      assert received_scopes.split.sort == old_received_scopes.split.sort,
             'Received scopes not equal to originally granted scopes'
    end
  end
end
