module SMART
  class OpenIDRetrieveConfigurationTest < Inferno::Test
    id :smart_openid_retrieve_configuration
    title 'OpenID Connect well-known configuration can be retrieved'
    description %(
        Verify that the OpenId Connect configuration can be retrieved as
        described in the OpenID Connect Discovery 1.0 documentation.
      )

    input :id_token_payload_json
    output :openid_configuration_json, :openid_issuer
    makes_request :openid_configuration

    run do
      skip_if id_token_payload_json.blank?

      payload = JSON.parse(id_token_payload_json)
      issuer = payload['iss']

      configuration_url = "#{issuer.chomp('/')}/.well-known/openid-configuration"
      get(configuration_url, name: :openid_configuration)

      assert_response_status(200)
      assert_response_content_type('application/json')
      assert_valid_json(response[:body])

      output openid_configuration_json: response[:body],
             openid_issuer: issuer
    end
  end
end
