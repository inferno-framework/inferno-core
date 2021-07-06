module SMART
  class SMARTSuite < Inferno::TestSuite
    id 'smart'
    title 'SMART'

    resume_test_route :get, '/launch' do
      request.query_parameters['iss']
    end

    group do
      id 'smart_group'
      title 'SMART Group'

      test do
        id 'auth_redirect'
        title 'OAuth server redirects client browser to app redirect URI'
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
