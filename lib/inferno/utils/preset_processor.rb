module Inferno
  module Utils
    class PresetProcessor
      attr_accessor :preset, :session, :suite

      def initialize(preset, session)
        self.preset = preset
        self.session = session
        self.suite = session.test_suite
      end

      def suite_inputs
        @suite_inputs ||= suite.available_inputs.transform_values(&:to_hash)
      end

      def inputs_to_persist
        preset.inputs.map do |input|
          input_for_options(input, session.suite_options)
        end
      end

      def input_for_options(input, suite_options)
        {
          name: input[:name],
          value: value(input, suite_options),
          type: suite_inputs[input[:name].to_sym][:type]
        }.reject { |processed_input| processed_input[:type].blank? }
      end

      def value(input, suite_options)
        value_for_option(input, suite_options).presence || input[:value]
      end

      def value_for_option(input, suite_options)
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
