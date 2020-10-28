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
    end
  end
end
