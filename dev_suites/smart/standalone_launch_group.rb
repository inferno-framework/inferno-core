require_relative 'app_redirect_test'
require_relative 'code_received_test'
require_relative 'token_exchange_test'
require_relative 'token_response_body_test'
require_relative 'token_response_headers_test'

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

    test from: :smart_app_redirect
    test from: :smart_code_received
    test from: :smart_token_exchange
    test from: :smart_token_response_body
    test from: :smart_token_response_headers
  end
end
