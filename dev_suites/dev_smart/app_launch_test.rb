module SMART
  class AppLaunchTest < Inferno::Test
    title 'EHR server redirects client browser to Inferno app launch URI'
    description %(
      Client browser sent from EHR server to app launch URI of client app as
      described in SMART EHR Launch Sequence.
    )
    id :smart_app_launch

    input :url
    receives_request :launch

    run do
      wait(
        identifier: url,
        message: %(
          Waiting to receive a request at
          /custom/smart/launch with an `iss` of `#{url}`.
        )
      )
    end
  end
end
