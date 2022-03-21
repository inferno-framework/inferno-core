module Inferno
  module Utils
    class PresetTemplateGenerator
      attr_accessor :runnable

      def initialize(runnable)
        self.runnable = runnable
      end

      def available_inputs
        @available_inputs ||= runnable.available_inputs.transform_values(&:to_hash)
      end

      def inputs
        # The rubocop rule is disabled because `each_value` returns the hash,
        # while `values.each` will return the array of values. We want the array
        # of values here.
        available_inputs.values.each do |input| # rubocop:disable Style/HashEachMethods
          input[:value] = (input.delete(:default) if input.key? :default)
        end
      end

      def metadata
        {
          title: "Preset for #{runnable.title}",
          id: nil
        }.merge(runnable.reference_hash)
      end

      def generate
        metadata.merge(
          inputs: inputs
        )
      end
    end
  end
end
