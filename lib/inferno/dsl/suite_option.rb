require_relative '../entities/attributes'

module Inferno
  module DSL
    # This class is used to represent TestSuite-level options which are selected
    # by the user, and can affect which tests/groups are displayed and run as
    # well as the behavior of those tests.
    #
    # @see Inferno::Entities::TestSuite.suite_option
    class SuiteOption
      ATTRIBUTES = [
        :id,
        :title,
        :default,
        :description,
        :list_options,
        :value
      ].freeze

      include Entities::Attributes

      # @!attribute [rw] id
      # @!attribute [rw] title
      # @!attribute [rw] default
      # @!attribute [rw] description
      # @!attribute [rw] list_options
      # @!attribute [rw] value

      # @private
      def initialize(raw_params)
        params = raw_params.deep_symbolize_keys
        bad_params = params.keys - ATTRIBUTES

        raise Exceptions::UnknownAttributeException.new(bad_params, self.class) if bad_params.present?

        params
          .compact
          .each { |key, value| send("#{key}=", value) }

        self.id = id.to_sym if id.is_a? String
      end

      # @private
      def ==(other)
        id == other.id && value == other.value
      end

      # @private
      def to_hash
        self.class::ATTRIBUTES.each_with_object({}) do |attribute, hash|
          hash[attribute] = send(attribute)
        end.compact
      end
    end
  end
end
