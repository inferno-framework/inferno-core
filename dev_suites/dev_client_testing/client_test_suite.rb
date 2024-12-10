# frozen_string_literal: true

require_relative 'client_test_endpoint'

module DevClientTesting
  class ClientTestSuite < Inferno::TestSuite
    title 'Client Test Suite'
    id :dev_client_test_suite
    description 'Inferno Core Developer Suite for testing clients.'

    suite_endpoint :get, '/client_test_endpoint', ClientTestEndpoint

    group do
      title 'Client Test Group'
      id :dev_client_test_group

      test do
        title 'Wait For Request'
        id :dev_wait_for_request_test
        output :uid

        receives_request :client_test_endpoint

        run do
          uid = SecureRandom.uuid
          output uid: uid

          wait(
            identifier: uid,
            message: <<~WAIT_FOR_REQUEST_MESSAGE
              Send a GET request to the following URL to continue:

              #{Inferno::Application['base_url']}/custom/dev_client_test_suite/client_test_endpoint?uid=#{uid}

              I.e:

              ```
              curl -X GET #{Inferno::Application['base_url']}/custom/dev_client_test_suite/client_test_endpoint?uid=#{uid}
              ```
            WAIT_FOR_REQUEST_MESSAGE
          )
        end
      end

      test do
        title 'Validate Request'
        id :dev_validate_request_test
        input :uid, optional: true

        uses_request :client_test_endpoint

        run do
          assert 200 == request.status
        end
      end
    end
  end
end
