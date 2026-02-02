# require 'onc_certification_g10_test_kit'
require_relative 'demo_endpoint'
require_relative 'groups/demo_group'

module DemoIG_STU1 # rubocop:disable Naming/ClassAndModuleCamelCase
  class DemoSuite < Inferno::TestSuite
    title 'Demonstration Suite'
    id 'demo'
    short_description 'Development suite for testing standard inputs and results'
    source_code_url 'https://github.com/inferno-framework/inferno-core'
    report_issue_url 'https://github.com/inferno-framework/inferno-core/issues'
    download_url 'https://github.com/inferno-framework/inferno-core/releases'
    ig_url 'http://example.com'

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

    check_configuration do
      [
        {
          type: 'info',
          message: 'This suite has a configuration info message'
        },
        {
          type: 'warning',
          message: 'This suite has a configuration warning message'
        }
      ]
    end

    fhir_resource_validator do
      exclude_message { |message| message.type == 'info' }
    end

    config options: {
      wait_test_url: "#{Inferno::Application['base_url']}/custom/demo/resume",
      wait_test_fail_url: "#{Inferno::Application['base_url']}/custom/demo/resume_fail",
      wait_test_skip_url: "#{Inferno::Application['base_url']}/custom/demo/resume_skip",
      wait_test_omit_url: "#{Inferno::Application['base_url']}/custom/demo/resume_omit",
      wait_test_cancel_url: "#{Inferno::Application['base_url']}/custom/demo/resume_cancel"
    }

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

      input_order :bearer_token, :patient_id, :url

      title 'Group 2'
      group from: 'DemoIG_STU1::DemoGroup', id: 'DEF', title: 'Demo Group Instance 2'
      group from: 'DemoIG_STU1::DemoGroup' do
        id 'GHI'
        title 'Optional Demo Group Instance 3'
        optional
      end
    end

    group do
      id 'conditional_group'
      title 'Conditional Inputs Group'
      optional

      test 'Conditional, optional, empty input test' do
        input :get_type, title: 'How to get Bundle', type: 'radio', options: {
          list_options: [
            { value: 'copy_paste', label: 'Paste JSON' },
            { value: 'url', label: 'URL to FHIR Bundle' },
            { value: 'summary_op', label: '$summary Operation' }
          ]
        }
        input :bundle_copy_paste, title: 'Paste JSON', type: 'textarea', optional: true,
                                  enable_when: { input_name: 'get_type', value: 'copy_paste' }
        input :bundle_url, title: 'URL to FHIR Bundle', type: 'text', optional: true,
                           enable_when: { input_name: 'get_type', value: 'url' }
        input :fhir_server_url, title: 'FHIR Server URL', type: 'text', optional: true,
                                enable_when: { input_name: 'get_type', value: 'summary_op' }
        input :patient_id, title: 'Patient ID', type: 'text', optional: true,
                           enable_when: { input_name: 'get_type', value: 'summary_op' }

        run { pass }
      end
    end

    group do
      id 'locked_group'
      title 'Locked Inputs Group'
      optional

      test 'Locked, required, empty input test' do
        input :locked_required_empty, title: 'Locked and Required (should not be runnable)',
                                      description: 'Example of locked, empty, required field',
                                      locked: true
        run { pass }
      end

      test 'Locked, required, filled input test' do
        input :locked_required_filled, title: 'Locked and Required (should be runnable)',
                                       description: 'Example of locked, filled, required field',
                                       default: 'example text',
                                       locked: true
        run { pass }
      end

      test 'Locked, optional, empty input test' do
        input :locked_optional_empty, title: 'Locked and Optional (should be runnable)',
                                      description: 'Example of locked, empty, optional field',
                                      locked: true,
                                      optional: true
        run { pass }
      end

      test 'Locked, optional, filled input test' do
        input :locked_optional_filled, title: 'Locked and Optional (should be runnable)',
                                       description: 'Example of locked, filled, optional field',
                                       default: 'example text',
                                       locked: true,
                                       optional: true
        run { pass }
      end
    end

    group do
      id 'hidden_group'
      title 'Hidden Inputs Group'
      description 'This group contains inputs that are either optional or locked and hidden from the UI.'

      optional

      test 'Hidden, optional, empty input test' do
        input :hidden_optional_empty, title: 'Hidden and Optional (should be runnable)',
                                      description: 'Example of hidden, empty, optional field',
                                      hidden: true,
                                      optional: true
        run { assert hidden_optional_empty.nil? }
      end

      test 'Hidden, optional, filled input test' do
        input :hidden_optional_filled, title: 'Hidden and Optional (should be runnable)',
                                       description: 'Example of hidden, filled, optional field',
                                       default: 'example text',
                                       hidden: true,
                                       optional: true
        run { assert hidden_optional_filled == 'example text' }
      end

      test 'Hidden, locked, filled input test' do
        input :hidden_locked_filled, title: 'Hidden and Locked (should be runnable)',
                                     description: 'Example of hidden, filled, locked field',
                                     default: 'example text',
                                     hidden: true,
                                     locked: true
        run { assert hidden_locked_filled == 'example text' }
      end

      test 'Hidden optional fields in AuthInfo input test' do
        input :auth_info_credentials,
              type: :auth_info, title: 'AuthInfo Credentials',
              description: 'Access mode AuthInfo input with `issue_time` and `expires_in` fields hidden',
              options: {
                mode: 'access',
                components: [
                  { name: :issue_time, optional: true, hidden: true },
                  { name: :expires_in, optional: true, hidden: true }
                ]
              },
              default: AuthInfoConstants
                .public_access_default
                .merge({ issue_time: '2025-03-13T14:15:50-04:00' }).to_json
        run do
          auth_info = AuthInfoConstants.public_access_default.merge({ issue_time: '2025-03-13T14:15:50-04:00' })
          auth_info.each do |key, original_value|
            received_value = auth_info_credentials.send(key)
            assert received_value == original_value,
                   "Expected fhir_client auth info `#{key}` to equal `#{original_value}`, " \
                   "but received `#{received_value}`"
          end
        end
      end

      test 'Hidden locked field in AuthInfo input test' do
        input :auth_mode_credentials,
              type: :auth_info, title: 'Auth Mode AuthInfo Credentials',
              description: 'Auth mode AuthInfo input with `pkce_support` field hidden',
              options: {
                mode: 'auth',
                components: [
                  { name: :pkce_support, locked: true, hidden: true }
                ]
              },
              default: AuthInfoConstants.public_default.to_json
        run do
          AuthInfoConstants.public_default.each do |key, original_value|
            received_value = auth_mode_credentials.send(key)
            assert received_value == original_value,
                   "Expected fhir_client auth info `#{key}` to equal `#{original_value}`, " \
                   "but received `#{received_value}`"
          end
        end
      end
    end

    group do
      id 'wait_group'
      title 'Wait Group'

      resume_test_route :get, '/resume' do |request|
        request.query_parameters['xyz']
      end

      resume_test_route :get, '/resume_fail', result: 'fail' do |request|
        request.query_parameters['xyz']
      end

      resume_test_route :get, '/resume_skip', result: 'skip' do |request|
        request.query_parameters['xyz']
      end

      resume_test_route :get, '/resume_omit', result: 'omit' do |request|
        request.query_parameters['xyz']
      end

      resume_test_route :get, '/resume_cancel', result: 'cancel' do |request|
        request.query_parameters['xyz']
      end

      test do
        title 'Pass test'
        run { pass }
      end

      test do
        title 'Wait test'
        receives_request :resume

        run do
          wait(
            identifier: 'abc',
            message: %(
              [Follow this link to pass the test and proceed](#{config.options[:wait_test_url]}?xyz=abc).

              [Follow this link to fail the test and proceed](#{config.options[:wait_test_fail_url]}?xyz=abc).

              [Follow this link to skip the test and proceed](#{config.options[:wait_test_skip_url]}?xyz=abc).

              [Follow this link to omit the test and proceed](#{config.options[:wait_test_omit_url]}?xyz=abc).

              [Follow this link to cancel the test and proceed](#{config.options[:wait_test_cancel_url]}?xyz=abc).

              Waiting to receive a request at one of:

              ```#{config.options[:wait_test_url]}?xyz=abc```,

              ```#{config.options[:wait_test_fail_url]}?xyz=abc```,

              ```#{config.options[:wait_test_skip_url]}?xyz=abc```,

              ```#{config.options[:wait_test_omit_url]}?xyz=abc```,

              ```#{config.options[:wait_test_cancel_url]}?xyz=abc```.
            )
          )
        end
      end

      test do
        title 'Pass test'
        uses_request :resume
        run { pass }
      end
    end

    group do
      id 'easily_cancelled_test'
      title 'Tests that should be easily cancelled'

      test do
        title 'Pass Test'
        run { pass }
      end

      test do
        title 'Pausing test'
        input :cancel_pause_time, default: '30'

        run { sleep(cancel_pause_time.to_i) }
      end

      test do
        title 'Test after pause that would pass'

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

    group do
      title 'missing_inputs group'
      description %(
        This group demonstrates a bug with missing inputs. If the bug is fixed,
        you should be able to run this group with no problems. If the bug is
        present, you will get a 422 when attempting to run this group.
      )
      input :url1

      test do
        title 'TEST 1'
        output :url2

        run do
          output url2: 'abc'
        end
      end

      test do
        title 'TEST 2'
        input :url1, name: :url2

        run do
          info url1
          pass
        end
      end
    end

    group do
      title 'Custom Suite Endpoints'
      description %(
        This group demonstrates custom suite endpoint functionality.
      )

      input :custom_bearer_token,
            description: 'This bearer token will be used to identify the incoming request'

      suite_endpoint :post, '/suite_endpoint', DemoEndpoint

      test do
        title 'Wait for request to suite endpoint'

        run do
          wait(
            identifier: custom_bearer_token,
            message: "Waiting for a POST with bearer token: `#{custom_bearer_token}` to " \
                     "`#{Inferno::Application['base_url']}/custom/demo/suite_endpoint`"
          )
        end
      end

      test do
        title 'Named request from suite endpoint'
        uses_request :custom_request

        run do
          assert request.present?, 'Named request not found'
        end
      end

      test do
        title 'Tagged request from suite endpoint'

        run do
          load_tagged_requests('abc', 'def')
          assert request.present?, 'Tagged request not found'
        end
      end
    end
  end
end
