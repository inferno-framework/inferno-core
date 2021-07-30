module SMART
  class StandaloneLounchGroup < Inferno::TestGroup
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


    test do
      title 'OAuth server redirects client browser to app redirect URI'
      description %(
        Client browser redirected from OAuth server to redirect URI of client
        app as described in SMART authorization sequence.
      )

      input :client_id,
            :requested_scopes,
            :url,
            :smart_authorization_url,
            :well_known_authorization_url

      output :state
      receives_request :standalone_redirect

      run do
        output state: SecureRandom.uuid

        # TODO: get host name
        redirect_uris = ''

        oauth2_params = {
          'response_type' => 'code',
          'client_id' => client_id,
          'redirect_uri' => redirect_uris,
          'scope' => requested_scopes,
          'state' => state,
          'aud' => url
        }

        authorization_url = smart_authorization_url

        assert_valid_http_uri(
          authorization_url,
          "OAuth2 Authorization Endpoint: \"#{smart_authorization_url}\" is not a valid URI"
        )

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
            Redirect to: #{smart_authorization_url} Waiting to receive a request
            at /custom/smart/redirect with a state of `#{state}`.
          )
        )
      end
    end
  end
end
