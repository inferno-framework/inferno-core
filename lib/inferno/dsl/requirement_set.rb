module Inferno
  module DSL
    class RequirementSet
      ATTRIBUTES = [
        :identifier,
        :title,
        :actor,
        :requirements,
        :suite_options
      ].freeze

      include Entities::Attributes

      def initialize(raw_attributes_hash)
        attributes_hash = raw_attributes_hash.symbolize_keys

        invalid_keys = attributes_hash.keys - ATTRIBUTES

        raise Exceptions::UnknownAttributeException.new(invalid_keys, self.class) if invalid_keys.present?

        attributes_hash.each do |name, value|
          if name == :suite_options
            value = value&.map { |option_id, option_value| SuiteOption.new(id: option_id, value: option_value) }
          end

          instance_variable_set(:"@#{name}", value)
        end

        self.suite_options ||= []
      end

      def complete?
        requirements.blank? || requirements.casecmp?('all')
      end

      def referenced?
        requirements&.casecmp? 'referenced'
      end

      def filtered?
        !complete? && !referenced?
      end

      def expand_requirement_ids
        Entities::Requirement.expand_requirement_ids(requirements, identifier)
      end
    end
  end
end
