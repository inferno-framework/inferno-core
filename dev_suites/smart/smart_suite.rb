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

    group do
      id 'smart_group'
      title 'SMART Group'

      test do
        id 'ehr_launch'
        title 'EHR redirects client browser to app launch URI'
        receives_request :launch

        run do
          wait(
            identifier: 'abc',
            message: "Waiting to receive a request at /custom/smart/launch with an iss of 'abc'"
          )
        end
      end

      test do
        title 'Check stuff from the incoming request'
        uses_request :launch

        run do
          query_string =
            request
              .query_parameters
              .map { |name, value| "#{name}=#{value}" }
              .join('&')
          info "Received the following query parameters: #{query_string}"
        end
      end
    end
  end
end
