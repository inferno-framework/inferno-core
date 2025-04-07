module Inferno
  module DSL
    class RequirementSet
      ATTRIBUTES = [
        :requirement_set,
        :title,
        :actor,
        :requirements,
        :suite_options
      ]

      include Entities::Attributes

      def initialize(raw_attributes_hash)
        attributes_hash = raw_attributes_hash.symbolize_keys

        invalid_keys = attributes_hash.keys - ATTRIBUTES

        raise Exceptions::UnknownAttributeException.new(invalid_keys, self.class) if invalid_keys.present?

        attributes_hash.each { |name, value| instance_variable_set(:"@#{name}", value) }
      end
    end
  end
end
