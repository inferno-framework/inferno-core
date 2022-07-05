require_relative '../entities/attributes'

module Inferno
  module DSL
    class SuiteOption
      ATTRIBUTES = [
        :id,
        :title,
        :description,
        :list_options,
        :value
      ].freeze

      include Entities::Attributes

      def initialize(raw_params)
        params = raw_params.deep_symbolize_keys
        bad_params = params.keys - ATTRIBUTES

        raise Exceptions::UnknownAttributeException.new(bad_params, self.class) if bad_params.present?

        params
          .compact
          .each { |key, value| send("#{key}=", value) }

        self.id = id.to_sym if id.is_a? String
      end

      def ==(other)
        id == other.id && value == other.value
      end

      def to_hash
        self.class::ATTRIBUTES.each_with_object({}) do |attribute, hash|
          hash[attribute] = send(attribute)
        end.compact
      end
    end
  end
end
