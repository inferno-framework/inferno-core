require_relative 'discovery_group'
require_relative 'standalone_launch_group'

module SMART
  class SMARTSuite < Inferno::TestSuite
    id 'smart'
    title 'SMART'

    resume_test_route :get, '/launch' do
      request.query_parameters['iss']
    end

    resume_test_route :get, '/redirect' do
      request.query_parameters['state']
    end

    group from: :smart_discovery

    group from: :smart_standalone_launch
  end
end
