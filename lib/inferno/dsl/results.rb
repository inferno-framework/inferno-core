module Inferno
  module DSL
    # This module contains methods to set test results.
    module Results
      # Halt execution of the current test and mark it as passed.
      #
      # @param message [String]
      # @return [void]
      def pass(message = '')
        raise Exceptions::PassException, message
      end

      # Halt execution of the current test and mark it as passed if a condition
      # is true.
      #
      # @param test [Boolean]
      # @param message [String]
      # @return [void]
      def pass_if(test, message = '')
        raise Exceptions::PassException, message if test
      end

      # Halt execution of the current test and mark it as skipped. This method
      # can also take a block with an assertion, and if the assertion fails, the
      # test will skip rather than fail.
      #
      # @param message [String]
      # @return [void]
      #
      # @example
      #   if some_precondition_not_met?
      #     skip('Some precondition was not met.')
      #   end
      #
      #   skip do
      #     assert false, 'This test will skip rather than fail'
      #   end
      def skip(message = '')
        raise Exceptions::SkipException, message unless block_given?

        yield
      rescue Exceptions::AssertionException => e
        raise Exceptions::SkipException, e.message
      end

      # Halt execution of the current test and mark it as skipped if a condition
      # is true.
      #
      # @param test [Boolean]
      # @param message [String]
      # @return [void]
      def skip_if(test, message = '')
        raise Exceptions::SkipException, message if test
      end

      # Halt execution of the current test and mark it as omitted. This method
      # can also take a block with an assertion, and if the assertion fails, the
      # test will omit rather than fail.
      #
      # @param message [String]
      # @return [void]
      #
      # @example
      #   if behavior_does_not_need_to_be_tested?
      #     omit('Behavior does not need to be tested.')
      #   end
      #
      #   omit do
      #     assert false, 'This test will omit rather than fail'
      #   end
      def omit(message = '')
        raise Exceptions::OmitException, message unless block_given?

        yield
      rescue Exceptions::AssertionException => e
        raise Exceptions::OmitException, e.message
      end

      # Halt execution of the current test and mark it as omitted if a condition
      # is true.
      #
      # @param test [Boolean]
      # @param message [String]
      # @return [void]
      def omit_if(test, message = '')
        raise Exceptions::OmitException, message if test
      end

      # Halt execution of the current test and wait for execution to resume.
      #
      # @see Inferno::DSL::Runnable#resume_test_route
      # @example
      #   resume_test_route :get, '/launch' do
      #     request.query_parameters['iss']
      #   end
      #
      #   test do
      #     input :issuer
      #     receives_request :launch
      #
      #     run do
      #       wait(
      #         identifier: issuer,
      #         message: "Wating to receive a request with an issuer of #{issuer}"
      #       )
      #     end
      #   end
      # @param identifier [String] An identifier which can uniquely identify
      #   this test run based on an incoming request. This is necessary so that
      #   the correct test run can be resumed.
      # @param message [String]
      # @param timeout [Integer] Number of seconds to wait for an incoming
      #   request
      # @return [void]
      def wait(identifier:, message: '', timeout: 300)
        identifier(identifier)
        wait_timeout(timeout)

        raise Exceptions::WaitException, message
      end

      # @private
      def identifier(identifier = nil)
        @identifier ||= identifier
      end

      # @private
      def wait_timeout(timeout = nil)
        @wait_timeout ||= timeout
      end

      # Halt execution of the current test. This provided for testing purposes
      # and should not be used in real tests.
      #
      # @param message [String]
      # @private
      def cancel(message = '')
        raise Exceptions::CancelException, message
      end
    end
  end
end
