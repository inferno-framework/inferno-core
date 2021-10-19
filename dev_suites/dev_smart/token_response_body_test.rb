require_relative 'token_payload_validation'

module SMART
  class TokenResponseBodyTest < Inferno::Test
    include TokenPayloadValidation

    title 'Token exchange response body contains required information encoded in JSON'
    description %(
      The EHR authorization server shall return a JSON structure that includes
      an access token or a message indicating that the authorization request
      has been denied. `access_token`, `token_type`, and `scope` are required.
      `token_type` must be Bearer. `expires_in` is required for token
      refreshes.
    )
    id :smart_token_response_body

    input :requested_scopes
    output :id_token,
           :refresh_token,
           :access_token,
           :expires_in,
           :patient_id,
           :encounter_id,
           :received_scopes,
           :intent
    uses_request :token

    run do
      skip_if request.status != 200, 'Token exchange was unsuccessful'

      assert_valid_json(request.response_body)
      token_response_body = JSON.parse(request.response_body)

      output id_token: token_response_body['id_token'],
             refresh_token: token_response_body['refresh_token'],
             access_token: token_response_body['access_token'],
             expires_in: token_response_body['expires_in'],
             patient_id: token_response_body['patient'],
             encounter_id: token_response_body['encounter'],
             received_scopes: token_response_body['scope'],
             intent: token_response_body['intent']

      validate_required_fields_present(token_response_body, ['access_token', 'token_type', 'expires_in', 'scope'])
      validate_token_field_types(token_response_body)
      validate_token_type(token_response_body)
      check_for_missing_scopes(requested_scopes, token_response_body)

      assert access_token.present?, 'Token response did not contain an access token'
      assert token_response_body['token_type']&.casecmp('Bearer')&.zero?,
             '`token_type` field must have a value of `Bearer`'
    end
  end
end
