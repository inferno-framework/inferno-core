require_relative 'attributes'
require_relative '../exceptions'

module Inferno
  module Entities
    # This class represents an Input for a runnable.
    class Input
      ATTRIBUTES = [
        :name,
        :title,
        :description,
        :type,
        :default,
        :optional,
        :options,
        :locked,
        :value
      ].freeze
      include Entities::Attributes

      # These attributes require special handling when merging input
      # definitions.
      UNINHERITABLE_ATTRIBUTES = [
        # Locking an input only has meaning at the level it is locked.
        # Consider:
        # - ParentGroup
        #   - Group 1, input :a
        #   - Group 2, input :a, locked: true
        # The input 'a' should be only be locked when running Group 2 in
        # isolation. It should not be locked when running Group 1 or the
        # ParentGroup.
        :locked,
        # Input type is sometimes only a UI concern (e.g. text vs. textarea), so
        # it is common to not redeclare the type everywhere it's used and needs
        # special handling to avoid clobbering the type with the default (text)
        # type.
        :type
      ].freeze

      # These are the attributes that can be directly copied when merging a
      # runnable's input with the input of one of its children.
      INHERITABLE_ATTRIBUTES = (ATTRIBUTES - UNINHERITABLE_ATTRIBUTES).freeze

      # These are the attributes that can be directly copied when merging a
      # runnable's input with an input configuration.
      MERGEABLE_ATTRIBUTES = (ATTRIBUTES - [:type]).freeze

      def initialize(**params)
        bad_params = params.keys - ATTRIBUTES

        raise Exceptions::UnknownAttributeException.new(bad_params, self.class) if bad_params.present?

        params
          .compact
          .each { |key, value| send("#{key}=", value) }

        self.name = name.to_s if params[:name].present?
      end

      # @private
      # Merge this input with an input belonging to a child. Fields defined on
      # this input take precedence over those defined on the child input.
      def merge_with_child(child_input)
        return self if child_input.nil?

        INHERITABLE_ATTRIBUTES.each do |attribute|
          merge_attribute(attribute, primary_source: self, secondary_source: child_input)
        end

        self.type = child_input.type if child_input.present? && child_input.type != 'text'

        self
      end

      # @private
      # Merge this input with an input from a configuration. Fields defined in
      # the configuration take precedence over those defined on this input.
      def merge(other_input)
        return self if other_input.nil?

        MERGEABLE_ATTRIBUTES.each do |attribute|
          merge_attribute(attribute, primary_source: other_input, secondary_source: self)
        end

        self.type = other_input.type if other_input.type.present? && other_input.type != 'text'

        self
      end

      # @private
      # Merge an individual attribute. If the primary source contains the
      # attribute, that value will be used. Otherwise the value from the
      # secondary source will be used.
      # @param attribute [Symbol]
      # @param primary_source [Input]
      # @param secondary_source [Input]
      def merge_attribute(attribute, primary_source:, secondary_source:)
        value = primary_source.send(attribute)
        value = secondary_source.send(attribute) if value.nil?

        return if value.nil?

        send("#{attribute}=", value)
      end

      def to_hash
        ATTRIBUTES.each_with_object({}) do |attribute, hash|
          value = send(attribute)
          next if value.nil?

          hash[attribute] = value
        end
      end

      def ==(other)
        return false unless other.is_a? Input

        ATTRIBUTES.all? { |attribute| send(attribute) == other.send(attribute) }
      end
    end
  end
end
