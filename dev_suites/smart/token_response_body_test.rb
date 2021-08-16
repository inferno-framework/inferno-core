module SMART
  class TokenResponseBodyTest < Inferno::Test
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
    output :standalone_id_token,
           :standalone_refresh_token,
           :standalone_access_token,
           :standalone_expires_in,
           :standalone_patient_id,
           :standalone_encounter_id,
           :standalone_received_scopes,
           :standalone_intent
    uses_request :standalone_token

    run do
      skip_if request.status != 200, 'Token exchange was unsuccessful'

      assert_valid_json(request.response_body)
      token_response_body = JSON.parse(request.response_body)

      output standalone_id_token: token_response_body['id_token'],
             standalone_refresh_token: token_response_body['refresh_token'],
             standalone_access_token: token_response_body['access_token'],
             standalone_expires_in: token_response_body['expires_in'],
             standalone_patient_id: token_response_body['patient'],
             standalone_encounter_id: token_response_body['encounter'],
             standalone_received_scopes: token_response_body['scope'],
             standalone_intent: token_response_body['intent']

      assert standalone_access_token.present?, 'Token response did not contain an access token'
      assert token_response_body['token_type']&.casecmp('Bearer')&.zero?,
             '`token_type` field must have a value of `Bearer`'
    end
  end
end
