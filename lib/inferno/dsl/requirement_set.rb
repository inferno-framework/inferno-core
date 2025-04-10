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
            value = value&.map { |option_id, option_value| SuiteOption.new(id: option_id, value: option_value) } || []
          end

          instance_variable_set(:"@#{name}", value)
        end
      end

      def complete?
        requirements.blank? || requirements.casecmp?('all')
      end

      def referenced?
        requirements.casecmp? 'referenced'
      end

      def filtered?
        !complete? && !referenced?
      end

      def expand_requirement_ids
        return [] if requirements.blank?

        current_set = nil
        requirements
          .split(',')
          .map(&:strip)
          .flat_map do |requirement_string|
            current_set, requirement_string = requirement_string.split('@') if requirement_string.include?('@')

            requirement_ids =
              if requirement_string.include? '-'
                start_id, end_id = requirement_string.split('-')
                (start_id..end_id).to_a
              else
                [requirement_string]
              end

            requirement_ids.map { |id| "#{current_set}@#{id}" }
          end
      end
    end
  end
end
