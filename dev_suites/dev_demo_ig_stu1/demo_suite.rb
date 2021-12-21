require_relative 'groups/demo_group'

module DemoIG_STU1 # rubocop:disable Naming/ClassAndModuleCamelCase
  class DemoSuite < Inferno::TestSuite
    title 'Demonstration Suite'
    id 'demo'

    # Ideas:
    # * Suite metadata (name, associated ig, version, etc etc)
    # * Be able to define new sequences that map inputs, force certain parameters, etc
    # * Allow suites / groups to have inputs (for suites inputs, have it be like what 'url'
    #   is for legacy inferno)
    # * Different types of gruops
    # * Default group?
    # * Sequences in groups should be uniquely identified, basically what inferno 'test cases'
    #   are.  Group id + sequence id.

    # group title: 'the first group',
    #   id: :first_group,
    #   link: 'http://example.com',
    #   description: %( This is the description for the first test! ) do

    # This is a little too simplistic, because we want groups to be able to
    # restrict params, map params, etc

    validator do
      url ENV.fetch('VALIDATOR_URL')
      exclude_message { |message| message.type == 'info' }
    end

    group :oauth_validator_demo do
      title 'OAuth credentials proof of concept'

      group :output_example do
        title 'Launch that would provide a bearer token & relevant content from code exchange response'
        output :creds

        test do
          title 'hi'
          id :something

          run do
            creds = {
              access_token: 'blah',
              refresh_token: 'blah, blah',
              expires_in: 400,
              client_id: 'hi',
              client_secret: 'bye',
              token_url: 'https://example.com'
            }.to_json

            output creds: creds
          end
        end
      end

      group :input_example do
        title 'Some simple test that may use smart credentials'
        input :url
        input :patient_id
        input :creds, type: 'oauth_credentials' # this is json, but types probably should have their own classes...

        fhir_client :creds_client do
          url :url
          oauth_credentials :creds
        end

        test do
          id :oauth_creds_use
          title 'Patient read with OAuth creds'
          input :patient_id, title: 'Patient ID'

          run do
            fhir_read(:patient, patient_id, client: :creds_client)

            assert_response_status(200)
            assert_resource_type(:patient)
          end
        end

        test do
          title 'hi'
          id :something
          output :creds

          run do
            creds = {
              access_token: 'refreshed blah token',
              refresh_token: 'blah, blah',
              expires_in: 400,
              client_id: 'hi',
              client_secret: 'bye',
              token_url: 'https://example.com'
            }.to_json

            output creds: creds
          end
        end
      end

      # test 'OAuth credentials outputted' do
      #   id :first_test
      #   output :creds

      #   run do

      #     creds = {
      #       access_token: 'blah',
      #       refresh_token: 'blah, blah',
      #       refresh_date: '5/5/555'
      #     }.to_json

      #     output creds: 'hi'

      #   end

      # end
    end

    group do
      id :simple_group
      title 'Group 1'
      group from: 'DemoIG_STU1::DemoGroup', title: 'Demo Group Instance 1'
    end

    # Note that in order to support test procedures that run the same group
    # under different conditions, groups in groups need to be considered
    # separate groups (so their results don't collide)
    group do
      id :repetitive_group
      title 'Group 2'
      group from: 'DemoIG_STU1::DemoGroup', id: 'DEF', title: 'Demo Group Instance 2'
      group from: 'DemoIG_STU1::DemoGroup' do
        id 'GHI'
        title 'Demo Group Instance 3'
      end
    end

    group do
      id 'wait_group'
      title 'Wait Group'

      resume_test_route :get, '/resume' do
        request.query_parameters['xyz']
      end

      test do
        title 'Pass test'
        run { pass }
      end

      test do
        title 'Wait test'
        receives_request :resume

        run { wait(identifier: 'abc') }
      end

      test do
        title 'Pass test'
        uses_request :resume
        run { pass }
      end
    end

    group do
      id 'run_as_group_examples'
      title 'Run as Group Examples'

      group do
        id 'run_as_group_multi'
        title 'Run as Group On (nested groups)'
        run_as_group

        group do
          id 'run_as_group_on'
          title 'Run as group also set at this level (should not be runnable)'
          run_as_group

          test do
            title 'Test should not be runnable'
            run { pass }
          end

          test do
            title 'Test should not be runnable'
            run { pass }
          end
        end

        group do
          id 'run_as_group_off'
          title 'Run as group not set at this level (should not be runnable)'

          test do
            title 'Test should not be runnable'
            run { pass }
          end

          test do
            title 'Test should not be runnable'
            run { pass }
          end
        end
      end

      group do
        id 'run_as_group_single'
        title 'Run as Group On (no nested groups)'
        run_as_group

        test do
          title 'Test should not be runnable'
          run { pass }
        end

        test do
          title 'Test should not be runnable'
          run { pass }
        end
      end
    end
  end
end
