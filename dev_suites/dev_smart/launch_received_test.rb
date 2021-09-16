module SMART
  class LaunchReceivedTest < Inferno::Test
    title 'EHR server sends launch parameter'
    description %(
      Code is a required querystring parameter on the redirect.
    )
    id :smart_launch_received

    output :launch
    uses_request :launch

    run do
      launch = request.query_parameters['launch']
      output launch: launch

      assert launch.present?, 'No `launch` paramater received'
    end
  end
end
