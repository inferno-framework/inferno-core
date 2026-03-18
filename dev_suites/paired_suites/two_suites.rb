module PairedSuites
  class SuiteA < Inferno::TestSuite
    title 'Paired Suite A'
    id 'paired_suite_a'
    short_description 'Paired Suite A to demonstrate exection against Suite B'

    resume_test_route :get, '/resume' do |request|
      request.query_parameters['xyz']
    end

    group do
      id 'wait_for_signals'
      title 'Wait For Signals Group'

      test do
        title 'Wait For First Signal'
        id 'wait_for_signal_one'

        output :wait_test_url

        run do
          identifier = 'one'
          wait_test_url = "#{Inferno::Application['base_url']}/custom/paired_suite_a/resume?xyz=#{identifier}"
          output(wait_test_url:)
          wait(
            identifier:,
            message: %(
              Waiting for a first signal from Suite B at #{wait_test_url}
            )
          )
        end
      end

      test do
        title 'Wait For Second Signal'
        id 'wait_for_signal_two'

        output :wait_test_url

        run do
          identifier = 'two'
          wait_test_url = "#{Inferno::Application['base_url']}/custom/paired_suite_a/resume?xyz=#{identifier}"
          output(wait_test_url:)
          wait(
            identifier:,
            message: %(
              Waiting for a second signal from Suite B at #{wait_test_url}
            )
          )
        end
      end

      test do
        title 'Wait For Third Signal'
        id 'wait_for_signal_three'

        output :wait_test_url

        run do
          identifier = 'three'
          wait_test_url = "#{Inferno::Application['base_url']}/custom/paired_suite_a/resume?xyz=#{identifier}"
          output(wait_test_url:)
          wait(
            identifier:,
            message: %(
              Waiting for a third signal from Suite B at #{wait_test_url}
            )
          )
        end
      end
    end
  end

  class SuiteB < Inferno::TestSuite
    title 'Paired Suite B'
    id 'paired_suite_b'
    short_description 'Paired Suite B to demonstrate exection against Suite A'

    resume_test_route :get, '/resume' do |request|
      request.query_parameters['xyz']
    end

    http_client do
      url Inferno::Application['base_url']
    end

    group do
      id 'send_signals'
      title 'Send Signals Group'

      test do
        title 'Send First Signal'
        id 'send_signal_one'

        run do
          get 'custom/paired_suite_a/resume?xyz=one'
        end
      end

      test do
        title 'Attest First Signal Received'
        id 'attest_signal_one'

        output :wait_test_url

        run do
          identifier = 'one'
          wait_test_url = "#{Inferno::Application['base_url']}/custom/paired_suite_b/resume?xyz=#{identifier}"
          output(wait_test_url:)
          wait(
            identifier:,
            message: %(
              [Attest that the first signal has been received](#{wait_test_url})
            )
          )
        end
      end

      test do
        title 'Send Second Signal'
        id 'send_signal_two'

        run do
          sleep 6
          get 'custom/paired_suite_a/resume?xyz=two'
        end
      end

      test do
        title 'Attest Second Signal Received'
        id 'attest_signal_two'

        output :wait_test_url

        run do
          identifier = 'two'
          wait_test_url = "#{Inferno::Application['base_url']}/custom/paired_suite_b/resume?xyz=#{identifier}"
          output(wait_test_url:)
          wait(
            identifier:,
            message: %(
              [Attest that the second signal has been received](#{wait_test_url})
            )
          )
        end
      end

      test do
        title 'Send Third Signal'
        id 'send_signal_three'

        run do
          get 'custom/paired_suite_a/resume?xyz=three'
        end
      end
    end
  end
end
