# frozen_string_literal: true

module DevClientTesting
  class ClientTestSuite < Inferno::TestSuite
    title 'Client Test Suite'
    id :dev_client_test_suite
    description 'Inferno Core Developer Suite for testing clients.'

    ## BUG: this endpoint is return 302 Found instead of 200 OK
    route(:get, 'client_test_endpoint', ->(rack_env) { [200, {'Content-Type' => 'application/json'}, JSON.pretty_generate(rack_env).split] })

    resume_test_route :get, '/client_test_endpoint' do |request|
      request.query_parameters['uid']
    end

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
          assert request.query_parameters[:uid] == uid
        end
      end
    end
  end
end
