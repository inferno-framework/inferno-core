require_relative '../dsl'
require_relative '../repositories/tests'

module Inferno
  module Entities
    class Test
      extend Forwardable
      include DSL

      def_delegators 'self.class', :title, :id, :block, :inputs, :outputs

      attr_accessor :result_message
      attr_reader :inputs, :test_session_id

      def initialize(**params)
        @inputs = params[:inputs]
        @test_session_id = params[:test_session_id]
      end

      def messages
        @messages ||= []
      end

      def add_message(type, message)
        messages << { type: type.to_s, message: message }
      end

      # Set output values. Once set, these values will be available to any
      # subsequent tests.
      #
      # @param outputs [Hash]
      # @return [void]
      # @example
      #   output(patient_id: '5', bearer_token: 'ABC')
      def output(outputs)
        outputs.each do |key, value|
          send("#{key}=", value)
        end
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

      def method_missing(name, *args, &block)
        parent_instance = self.class.parent&.new
        if parent_instance.respond_to?(name)
          parent_instance.send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, _include_private = false)
        self.class.parent&.new&.respond_to?(name)
      end

      class << self
        # Define inputs for this Test
        #
        # @param inputs [Symbol]
        # @return [void]
        # @example
        #   input :patient_id, :bearer_token
        def input(*input_definitions)
          super

          input_definitions.each do |input|
            if input.is_a? Hash
              attr_reader input[:key]
            else
              attr_reader input
            end
          end
        end

        # Define outputs for this Test
        #
        # @param output_definitions [Symbol]
        # @return [void]
        # @example
        #   output :patient_id, :bearer_token
        def output(*output_definitions)
          super

          output_definitions.each do |output|
            attr_accessor output
          end
        end

        def repository
          Inferno::Repositories::Tests.new
        end

        def block(&block)
          return @block unless block_given?

          @block = block
        end

        alias run block

        def default_id
          return name if name.present?

          suffix = parent ? (parent.tests.find_index(self) + 1).to_s.rjust(2, '0') : SecureRandom.uuid
          "Test#{suffix}"
        end

        def reference_hash
          {
            test_id: id
          }
        end

        def method_missing(name, *args, &block)
          parent_instance = parent&.new
          if parent_instance.respond_to?(name)
            parent_instance.send(name, *args, &block)
          else
            super
          end
        end

        def respond_to_missing?(name, _include_private = false)
          parent&.new&.respond_to?(name)
        end
      end
    end
  end

  Test = Entities::Test
end
