module SMART
  class AppRedirectTest < Inferno::Test
    title 'OAuth server redirects client browser to app redirect URI'
    description %(
      Client browser redirected from OAuth server to redirect URI of client
      app as described in SMART authorization sequence.
    )
    id :smart_app_redirect

    input :client_id, :requested_scopes, :url, :smart_authorization_url

    output :state
    receives_request :redirect

    config options: { redirect_uri: "#{Inferno::Application['inferno_host']}/custom/smart/redirect" }

    run do
      assert_valid_http_uri(
        smart_authorization_url,
        "OAuth2 Authorization Endpoint '#{smart_authorization_url}' is not a valid URI"
      )

      output state: SecureRandom.uuid

      oauth2_params = {
        'response_type' => 'code',
        'client_id' => client_id,
        'redirect_uri' => config.options[:redirect_uri],
        'scope' => requested_scopes,
        'state' => state,
        'aud' => url
      }

      oauth2_params['launch'] = launch if self.class.inputs.include?(:launch)

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
          [Follow this link to authorize with the SMART
          server](#{authorization_url}). Waiting to receive a request at
          `#{config.options[:redirect_uri]}` with a state of `#{state}`.
        )
      )
    end
  end
end
