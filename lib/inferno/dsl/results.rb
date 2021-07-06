module Inferno
  module DSL
    # This module contains methods to set test results.
    module Results
      # Halt execution of the current test and mark it as passed.
      #
      # @param message [String]
      def pass(message = '')
        raise Exceptions::PassException, message
      end

      # Halt execution of the current test and mark it as passed if a condition
      # is true.
      #
      # @param test [Boolean]
      # @param message [String]
      def pass_if(test, message = '')
        raise Exceptions::PassException, message if test
      end

      # Halt execution of the current test and mark it as skipped.
      #
      # @param message [String]
      def skip(message = '')
        raise Exceptions::SkipException, message
      end

      # Halt execution of the current test and mark it as skipped if a condition
      # is true.
      #
      # @param test [Boolean]
      # @param message [String]
      def skip_if(test, message = '')
        raise Exceptions::SkipException, message if test
      end

      # Halt execution of the current test and mark it as omitted.
      #
      # @param message [String]
      def omit(message = '')
        raise Exceptions::OmitException, message
      end

      # Halt execution of the current test and mark it as omitted if a condition
      # is true.
      #
      # @param test [Boolean]
      # @param message [String]
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
      def wait(identifier:, message: '', timeout: 300)
        identifier(identifier)
        wait_timeout(timeout)

        raise Exceptions::WaitException, message
      end

      def identifier(identifier = nil)
        @identifier ||= identifier
      end

      def wait_timeout(timeout = nil)
        @wait_timeout ||= timeout
      end

      # Halt execution of the current test. This provided for testing purposes
      # and should not be used in real tests.
      #
      # @param message [String]
      # @api private
      def cancel(message = '')
        raise Exceptions::CancelException, message
      end
    end
  end
end
