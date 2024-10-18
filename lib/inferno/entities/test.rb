require_relative '../dsl'
require_relative '../repositories/tests'
require 'pry'

module Inferno
  module Entities
    class Test
      extend Forwardable
      include DSL

      def_delegators 'self.class', :title, :id, :block, :inputs, :outputs

      attr_accessor :result_message
      attr_reader :test_session_id, :scratch, :suite_options

      # @private
      def initialize(**params)
        params[:inputs]&.each { |key, value| instance_variable_set("@#{key}", value) }
        @scratch = params[:scratch]
        @test_session_id = params[:test_session_id]
        @suite_options = params[:suite_options].presence || {}
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
          outputs_to_persist[key] = value
        end
      end

      # @private
      # A hash containing outputs that have been set during execution and need
      # to be persisted. A test may not always update all outputs, so this is
      # used to prevent overwriting an output with nil when it wasn't updated.
      def outputs_to_persist
        @outputs_to_persist ||= {}
      end

      # @private
      def method_missing(name, ...)
        parent_instance = self.class.parent&.new
        if parent_instance.respond_to?(name)
          parent_instance.send(name, ...)
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
        # @param _output_params [Hash] Unused parameter. Just makes method
        #   signature compatible with `Inferno::DSL::InputOutputHandling.output`
        # @return [void]
        # @example
        #   output :patient_id, :bearer_token
        def output(*output_definitions, **_output_params)
          super

          output_definitions.each do |output|
            attr_accessor output
          end
        end

        # @private
        def repository
          Inferno::Repositories::Tests.new
        end

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
        # Has an unused argument to match the method signature of Runnable#test_count
        def test_count(_ = nil)
          1
        end

        # @private
        def method_missing(name, ...)
          parent_instance = parent&.new
          if parent_instance.respond_to?(name)
            parent_instance.send(name, ...)
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
