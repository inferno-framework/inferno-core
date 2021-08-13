module SMART
  class StandaloneLaunchGroup < Inferno::TestGroup
    id :smart_standalone_launch
    title 'SMART Standalone Launch'

    description %(
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
    )

    def redirect_uri
      "#{Inferno::Application['inferno_host']}/custom/smart/redirect"
    end

    test do
      title 'OAuth server redirects client browser to app redirect URI'
      description %(
        Client browser redirected from OAuth server to redirect URI of client
        app as described in SMART authorization sequence.
      )

      input :client_id,
            :requested_scopes,
            :url,
            :smart_authorization_url

      output :state
      receives_request :standalone_redirect

      run do
        assert_valid_http_uri(
          smart_authorization_url,
          "OAuth2 Authorization Endpoint '#{smart_authorization_url}' is not a valid URI"
        )

        output state: SecureRandom.uuid

        oauth2_params = {
          'response_type' => 'code',
          'client_id' => client_id,
          'redirect_uri' => redirect_uri,
          'scope' => requested_scopes,
          'state' => state,
          'aud' => url
        }

        authorization_url = smart_authorization_url

        authorization_url +=
          if authorization_url.include? '?'
            '&'
          else
            '?'
          end

        oauth2_params.each do |key, value|
          authorization_url += "#{key}=#{CGI.escape(value)}&"
        end

        authorization_url.chomp!('&')

        wait(
          identifier: state,
          message: %(
            Redirect to: #{authorization_url} Waiting to receive a request
            at /custom/smart/redirect with a state of `#{state}`.
          )
        )
      end
    end

    test do
      title 'OAuth server sends code parameter'
      output :standalone_code
      uses_request :standalone_redirect

      run do
        code = request.query_parameters['code']
        output standalone_code: code

        assert code.present?, 'No `code` paramater received'

        error = request.query_parameters['error']

        pass_if error.blank?

        error_message = "Error returned from authorization server. code: '#{error}'"
        error_description = request.query_parameters['error_description']
        error_uri = request.query_parameters['error_uri']
        error_message += ", description: '#{error_description}'" if error_description.present?
        error_message += ", uri: #{error_uri}" if error_uri.present?

        assert false, error_message
      end
    end

    test do
      title 'OAuth token exchange request succeeds when supplied correct information'
      input :standalone_code,
            :smart_token_url,
            :client_id,
            :client_secret
      output :standalone_token_retrieval_time
      uses_request :standalone_redirect
      makes_request :standalone_token

      description %(
        After obtaining an authorization code, the app trades the code for an
        access token via HTTP POST to the EHR authorization server's token
        endpoint URL, using content-type application/x-www-form-urlencoded, as
        described in section [4.1.3 of
        RFC6749](https://tools.ietf.org/html/rfc6749#section-4.1.3).
      )

      run do
        skip_if request.query_parameters['error'].present?, 'Error during authorization request'

        oauth2_params = {
          grant_type: 'authorization_code',
          code: standalone_code,
          redirect_uri: redirect_uri
        }
        oauth2_headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

        if client_secret.present?
          client_credentials = "#{client_id}:#{client_secret}"
          oauth2_headers['Authorization'] = "Basic #{Base64.strict_encode64(client_credentials)}"
        else
          oauth2_params[:client_id] = client_id
        end

        post(smart_token_url, body: oauth2_params, name: :standalone_token, headers: oauth2_headers)

        output standalone_token_retrieval_time: Time.now.iso8601

        assert_response_status(200)
      end
    end

    test do
      title 'Token exchange response body contains required information encoded in JSON'
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

      description %(
        The EHR authorization server shall return a JSON structure that includes
        an access token or a message indicating that the authorization request
        has been denied. `access_token`, `token_type`, and `scope` are required.
        `token_type` must be Bearer. `expires_in` is required for token
        refreshes.
      )

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

    test do
      title 'Response includes correct HTTP Cache-Control and Pragma headers'
      uses_request :standalone_token

      description %(
        The authorization servers response must include the HTTP Cache-Control
        response header field with a value of no-store, as well as the Pragma
        response header field with a value of no-cache.
      )

      run do
        skip_if request.status != 200, 'Token exchange was unsuccessful'

        cc_header = request.response_header('Cache-Control')&.value

        assert cc_header&.downcase&.include?('no-store'),
               'Token response must have `Cache-Control` header containing `no-store`.'

        pragma_header = request.response_header('Pragma')&.value

        assert pragma_header&.downcase&.include?('no-cache'),
               'Token response must have `Pragma` header containing `no-cache`.'
      end
    end
  end
end
