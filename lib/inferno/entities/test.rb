require_relative '../dsl'
require_relative '../repositories/tests'
require_relative '../utils/markdown_formatter'
require 'pry'

module Inferno
  module Entities
    class Test
      extend Forwardable
      include DSL
      include Inferno::Utils::MarkdownFormatter

      def_delegators 'self.class', :title, :id, :block, :inputs, :outputs

      attr_accessor :result_message
      attr_reader :test_session_id, :scratch

      # @private
      def initialize(**params)
        params[:inputs]&.each { |key, value| instance_variable_set("@#{key}", value) }
        @scratch = params[:scratch]
        @test_session_id = params[:test_session_id]
      end

      # @private
      def messages
        @messages ||= []
      end

      def add_message(type, message)
        messages << { type: type.to_s, message: format_markdown(message) }
      end

      # Set output values. Once set, these values will be available to any
      # subsequent tests.
      #
      # @param outputs [Hash]
      # @return [void]
      # @example
      #   output(patient_id: '5', bearer_token: 'ABC')
      def output(outputs)
        # TODO: update to track outputs that need to be updated
        outputs.each do |key, value|
          send("#{key}=", value)
          outputs_to_persist[key] = value
        end
      end

      # @api private
      # A hash containing outputs that have been set during execution and need
      # to be persisted. A test may not always update all outputs, so this is
      # used to prevent overwriting an output with nil when it wasn't updated.
      def outputs_to_persist
        @outputs_to_persist ||= {}
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

      # @private
      def method_missing(name, *args, &block)
        parent_instance = self.class.parent&.new
        if parent_instance.respond_to?(name)
          parent_instance.send(name, *args, &block)
        else
          super
        end
      end

      # @private
      def respond_to_missing?(name, _include_private = false)
        self.class.parent&.new&.respond_to?(name)
      end

      class << self
        # Define inputs for this Test
        #
        # @param name [Symbol] name of the input
        # @param other_names [Symbol] array of symbols if specifying multiple inputs
        # @param input_params [Hash] options for input such as type, description, or title
        # @option input_params [String] :title Human readable title for input
        # @option input_params [String] :description Description for the input
        # @option input_params [String] :type 'text' | 'textarea'
        # @return [void]
        # @example
        #   input :patientid, title: 'Patient ID', description: 'The ID of the patient being searched for'
        # @example
        #   input :textarea, title: 'Textarea Input Example', type: 'textarea'
        def input(name, *other_names, **input_params)
          super

          if other_names.present?
            [name, *other_names].each { |input| attr_reader input }
          else
            attr_reader name
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

        # Set/Get the block that is executed when a Test is run
        #
        # @param block [Proc]
        # @return [Proc] the block that is executed when a Test is run
        def block(&block)
          return @block unless block_given?

          @block = block
        end

        alias run block

        def short_id
          @short_id ||= begin
            prefix = parent.respond_to?(:short_id) ? "#{parent.short_id}." : ''
            suffix = parent ? (parent.tests.find_index(self) + 1).to_s.rjust(2, '0') : 'x'
            "#{prefix}#{suffix}"
          end
        end

        # @private
        def default_id
          return name if name.present?

          suffix = parent ? (parent.tests.find_index(self) + 1).to_s.rjust(2, '0') : SecureRandom.uuid
          "Test#{suffix}"
        end

        # @private
        def reference_hash
          {
            test_id: id
          }
        end

        # @private
        def test_count
          1
        end

        # @private
        def method_missing(name, *args, &block)
          parent_instance = parent&.new
          if parent_instance.respond_to?(name)
            parent_instance.send(name, *args, &block)
          else
            super
          end
        end

        # @private
        def respond_to_missing?(name, _include_private = false)
          parent&.new&.respond_to?(name)
        end
      end
    end
  end

  Test = Entities::Test
end
