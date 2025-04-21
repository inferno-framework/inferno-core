module Inferno
  module DSL
    # A `RequirementSet` represents the set of requirements which are tested by
    # a TestSuite.
    #
    # @!attribute identifier [rw] The unique identifier for the source of
    #   requirements included in this `RequirementSet`
    # @!attribute title [rw] A human-readable title for this `RequirementSet`
    # @!attribute actor [rw] The actor whose requirements are included in this
    #   `RequirementSet`
    # @!attribute requirements [rw] There are three options:
    #   * `"all"` (default) - Include all of the requirements for the specified
    #     actor from the requirement source
    #   * `"referenced"` - Only include requirements from this source if they
    #     are referenced by other included requirements
    #   * `"1,3,5-8"` - Only include the requirements from a comma-delimited
    #     list
    # @!attribute suite_options [rw] A set of suite options which must be
    #   selected in order for this `RequirementSet` to be included
    #
    # @see Inferno::DSL::SuiteRequirements#requirement_sets
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

      # Returns true when the `RequirementSet` includes all of the requirements
      # from the source for the specified actor
      #
      # @return [Boolean]
      def complete?
        requirements.blank? || requirements.casecmp?('all')
      end

      # Returns true when the `RequirementSet` only includes requirements
      # referenced by other `RequirementSet`s
      #
      # @return [Boolean]
      def referenced?
        requirements&.casecmp? 'referenced'
      end

      # Returns true when the `RequirementSet` only includes requirements
      # specified in a list
      #
      # @return [Boolean]
      def filtered?
        !complete? && !referenced?
      end

      # Expands the compressed comma-separated requirements list into an Array
      # of full ids
      def expand_requirement_ids
        Entities::Requirement.expand_requirement_ids(requirements, identifier)
      end
    end
  end
end
