module Inferno
  module DSL
    # This module contains methods to add meessages to runnable results
    module Messages
      # @private
      def messages
        @messages ||= []
      end

      # Add a message to the result.
      #
      # @param type [String] error, warning, or info
      # @param message [String]
      # @return [void]
      def add_message(type, message)
        messages << { type: type.to_s, message: format_markdown(message) }
      end

      # Add an informational message to the results of a test. If passed a
      # block, a failed assertion will become an info message and test execution
      # will continue.
      #
      # @param message [String]
      # @return [void]
      # @example
      #   # Add an info message
      #   info 'This message will be added to the test results'
      #
      #   # The message for the failed assertion will be treated as an info
      #   # message. Test exection will continue.
      #   info { assert false == true }
      def info(message = nil)
        unless block_given?
          add_message('info', message) unless message.nil?
          return
        end

        yield
      rescue Exceptions::AssertionException => e
        add_message('info', e.message)
      end

      # Add a warning message to the results of a test. If passed a block, a
      # failed assertion will become a warning message and test execution will
      # continue.
      #
      # @param message [String]
      # @return [void]
      # @example
      #   # Add a warning message
      #   warning 'This message will be added to the test results'
      #
      #   # The message for the failed assertion will be treated as a warning
      #   # message. Test exection will continue.
      #   warning { assert false == true }
      def warning(message = nil)
        unless block_given?
          add_message('warning', message) unless message.nil?
          return
        end

        yield
      rescue Exceptions::AssertionException => e
        add_message('warning', e.message)
      end
    end
  end
end
