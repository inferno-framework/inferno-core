require 'json/jwt'

module ONCProgram
  class BulkDataAuthorization < Inferno::TestGroup
    title 'Bulk Data Authorization'
    description <<~DESCRIPTION
      Bulk Data servers are required to authorize clients using the
      [Backend Service Authorization](http://hl7.org/fhir/uv/bulkdata/STU1/authorization/)
      specification as defined in the [FHIR Bulk Data Authorization Guide](http://hl7.org/fhir/uv/bulkdata/STU1/).

      In this set of tests, Inferno serves as a Bulk Data client that attempts to authorize
      to the Bulk Data authorization server.  It also performs a number of negative tests
      to validate that the authorization service does not improperly authorize invalid
      requests.

      This test returns an access token.
    DESCRIPTION

    id :bulk_data_authorization

    input :bulk_token_endpoint
    output :bulk_access_token

    http_client :token_endpoint do
      url :bulk_token_endpoint 
    end

    # Locally stored JWK related code i.e. pulling from  bulk_data_jwks.json. 
    # Takes an encryption method as a string and filters for the corresponding
    # key. The :bulk_encryption_method symbol was not recognized from within the
    # scope of this method, hence why its passed as a parameter. 
    #
    # In program, this information was set within the config.yml file and related
    # methods written within the testing_instance.rb file. The following
    # code cherry picks what was needed from those files, but we should probably
    # make an organizational decision about where this stuff will live. 
    def get_bulk_selected_private_key(encryption)
      binding.pry
      bulk_data_jwks = JSON.parse(File.read(File.join(File.dirname(__FILE__), 'bulk_data_jwks.json')))
      bulk_private_key_set = bulk_data_jwks['keys'].select { |key| key['key_ops']&.include?('sign') }
      bulk_private_key_set.find { |key| key['alg'] == encryption }
    end

    # Heavy lifting for authorization - token signing and the like. 
    #
    # Returns a hash containing everything necessary for an authorization post
    # request. I ran into difficulty trying to make the request from within the 
    # authorize function itself. I think its because the http_client is only 
    # usable from within the 'test' context - which is too bad because making the
    # request from within this function would be cleaner.  
    def authorize(bulk_encryption_method,
                  scope,
                  iss,
                  sub,
                  aud,
                  content_type: 'application/x-www-form-urlencoded',
                  grant_type: 'client_credentials',
                  client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
                  exp: 5.minutes.from_now,
                  jti: SecureRandom.hex(32))
      header = 
        {
          content_type: content_type,
          accept: 'application/json'
        }.compact

      bulk_private_key = get_bulk_selected_private_key(bulk_encryption_method)
      jwt_token = JSON::JWT.new(iss: iss, sub: sub, aud: aud, exp: exp, jti: jti).compact
      jwk = JSON::JWK.new(bulk_private_key)

      jwt_token.kid = jwk['kid']
      jwk_private_key = jwk.to_key
      client_assertion = jwt_token.sign(jwk_private_key, bulk_private_key['alg'])

      query_values =
        {
          'scope' => scope,
          'grant_type' => grant_type,
          'client_assertion_type' => client_assertion_type,
          'client_assertion' => client_assertion.to_s
        }.compact

      uri = Addressable::URI.new
      uri.query_values = query_values

      return { body: uri.query, headers: header } 
    end 

    test do
      title 'Authorization service token endpoint secured by transport layer security'
      description <<~DESCRIPTION
        [§170.315(g)(10) Test Procedure](https://www.healthit.gov/test-method/standardized-api-patient-and-population-services) requires that
        all exchanges described herein between a client and a server SHALL be secured using Transport Layer Security (TLS) Protocol Version 1.2 (RFC5246).
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/export/index.html#security-considerations'

      run {
        assert_valid_http_uri(bulk_token_endpoint, "Invalid token endpoint: #{bulk_token_endpoint}")
      }
    end

    test do
      title 'Authorization request fails when client supplies invalid grant_type'
      description <<~DESCRIPTION
        The Backend Service Authorization specification defines the required fields for the
        authorization request, made via HTTP POST to authorization token endpoint.
        This includes the `grant_type` parameter, where the value must be `client_credentials`.

        The OAuth 2.0 Authorization Framework describes the proper response for an
        invalid request in the client credentials grant flow:

        ```
        If the request failed client authentication or is invalid, the authorization server returns an
        error response as described in [Section 5.2](https://tools.ietf.org/html/rfc6749#section-5.2).
        ```
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/authorization/index.html#protocol-details'

      input :bulk_encryption_method, :bulk_scope, :bulk_client_id

      run {
        post_request_content = authorize(bulk_encryption_method, 
                             bulk_scope, 
                             bulk_client_id,
                             bulk_client_id, 
                             bulk_token_endpoint,
                             grant_type: 'not_a_grant_type')
              
        post(post_request_content.merge({:client => :token_endpoint}))

        assert_response_status(400)
      }
    end

    test do
      title 'Authorization request fails when supplied invalid client_assertion_type'
      description <<~DESCRIPTION
        The Backend Service Authorization specification defines the required fields for the
        authorization request, made via HTTP POST to authorization token endpoint.
        This includes the `client_assertion_type` parameter, where the value must be `urn:ietf:params:oauth:client-assertion-type:jwt-bearer`.

        The OAuth 2.0 Authorization Framework describes the proper response for an
        invalid request in the client credentials grant flow:

        ```
        If the request failed client authentication or is invalid, the authorization server returns an
        error response as described in [Section 5.2](https://tools.ietf.org/html/rfc6749#section-5.2).
        ```
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/authorization/index.html#protocol-details'

      input :bulk_encryption_method, :bulk_scope, :bulk_client_id

      run {
        post_request_content = authorize(bulk_encryption_method, 
                             bulk_scope, 
                             bulk_client_id,
                             bulk_client_id, 
                             bulk_token_endpoint,
                             client_assertion_type: 'not_a_assertion_type')
              
        post(post_request_content.merge({:client => :token_endpoint}))

        assert_response_status(400)
      }
    end

    test do
      title 'Authorization request fails when client supplies invalid JWT token'
      description <<~DESCRIPTION
        The Backend Service Authorization specification defines the required fields for the
        authorization request, made via HTTP POST to authorization token endpoint.
        This includes the `client_assertion` parameter, where the value must be
        a valid JWT. The JWT SHALL include the following claims, and SHALL be signed with the client’s private key.

        | JWT Claim | Required? | Description |
        | --- | --- | --- |
        | iss | required | Issuer of the JWT -- the client's client_id, as determined during registration with the FHIR authorization server (note that this is the same as the value for the sub claim) |
        | sub | required | The service's client_id, as determined during registration with the FHIR authorization server (note that this is the same as the value for the iss claim) |
        | aud | required | The FHIR authorization server's "token URL" (the same URL to which this authentication JWT will be posted) |
        | exp | required | Expiration time integer for this authentication JWT, expressed in seconds since the "Epoch" (1970-01-01T00:00:00Z UTC). This time SHALL be no more than five minutes in the future. |
        | jti | required | A nonce string value that uniquely identifies this authentication JWT. |

        The OAuth 2.0 Authorization Framework describes the proper response for an
        invalid request in the client credentials grant flow:

        ```
        If the request failed client authentication or is invalid, the authorization server returns an
        error response as described in [Section 5.2](https://tools.ietf.org/html/rfc6749#section-5.2).
        ```
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/authorization/index.html#protocol-details'

      input :bulk_encryption_method, :bulk_scope, :bulk_client_id

      run {
        post_request_content = authorize(bulk_encryption_method, 
                             bulk_scope, 
                             'not-a-valid-iss', 
                             bulk_client_id, 
                             bulk_token_endpoint)

        post(post_request_content.merge({:client => :token_endpoint}))

        assert_response_status(400)
      }
    end

    test do
      title 'Authorization request succeeds when supplied correct information'
      description <<~DESCRIPTION
        If the access token request is valid and authorized, the authorization server SHALL issue an access token in response.
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/authorization/index.html#issuing-access-tokens'

      input :bulk_encryption_method, :bulk_scope, :bulk_client_id

      run {
        post_request_content = authorize(bulk_encryption_method, 
          bulk_scope, 
          bulk_client_id,
          bulk_client_id, 
          bulk_token_endpoint)

        response = post(post_request_content.merge({:client => :token_endpoint}))

        assert_response_status([200, 201])
        @access_token = response
      }
    end

    test do
      title 'Authorization request response body contains required information encoded in JSON'
      description <<~DESCRIPTION
        The access token response SHALL be a JSON object with the following properties:

        | Token Property | Required? | Description |
        | --- | --- | --- |
        | access_token | required | The access token issued by the authorization server. |
        | token_type | required | Fixed value: bearer. |
        | expires_in | required | The lifetime in seconds of the access token. The recommended value is 300, for a five-minute token lifetime. |
        | scope | required | Scope of access authorized. Note that this can be different from the scopes requested by the app. |
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/authorization/index.html#issuing-access-tokens'

      run {}
    end
  end
end
