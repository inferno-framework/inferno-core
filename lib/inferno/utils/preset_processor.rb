module Inferno
  module Utils
    # This class determines which values to use in a preset based on the suite
    # options chosen in a session.
    # @api private
    class PresetProcessor
      attr_accessor :preset, :session, :suite, :suite_inputs, :suite_options

      def initialize(preset, session)
        self.preset = preset
        self.session = session
        self.suite = session.test_suite
        self.suite_inputs = suite.available_inputs.transform_values(&:to_hash)
        self.suite_options = session.suite_options
      end

      # Returns the list of inputs which need to be persisted, with options
      # applied.
      def processed_inputs
        preset.inputs
          .map { |input| input_for_options(input) }
          .compact
      end

      private

      def input_for_options(input)
        if suite_inputs[input[:name].to_sym].nil?
          Inferno::Application['logger'].warn("Unknown input #{input[:name]} in preset #{preset.id}")
          return
        end

        {
          name: input[:name],
          value: value(input),
          type: suite_inputs[input[:name].to_sym][:type]
        }
      end

      def value(input)
        value_for_option(input).presence || input[:value]
      end

      def value_for_option(input)
        input[:value_for_options]&.find do |option_value|
          option_value[:options].all? do |option|
            suite_options.any? do |suite_option|
              suite_option.id.to_s == option[:name] && suite_option.value == option[:value]
            end
          end
        end&.dig(:value)
      end
    end
  end
end
