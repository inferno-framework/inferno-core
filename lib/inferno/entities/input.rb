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
        :hidden,
        :value,
        :show_if
      ].freeze
      include Entities::Attributes

      # These attributes require special handling when merging input
      # definitions.
      UNINHERITABLE_ATTRIBUTES = [
        # Locking, hiding, or conditional display only have meaning at the level
        # they are applied. Consider:
        # - ParentGroup
        #   - Group 1, input :a
        #   - Group 2, input :a, locked: true, hidden: true, show_if: {...}, optional: true
        # The input 'a' should only be locked, hidden, or conditionally shown when
        # running Group 2 in isolation. It should not inherit those when running
        # Group 1 or the ParentGroup.
        :locked,
        :hidden,
        :show_if,
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
      MERGEABLE_ATTRIBUTES = (ATTRIBUTES - [:type, :options]).freeze

      def initialize(**params)
        bad_params = params.keys - ATTRIBUTES

        raise Exceptions::UnknownAttributeException.new(bad_params, self.class) if bad_params.present?

        if params[:hidden] && !params[:optional] && !params[:locked]
          raise Exceptions::InvalidAttributeException.new(
            :hidden,
            self.class,
            "Input '#{params[:name]}' cannot be hidden unless it is optional or locked."
          )
        end

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

        merge_options(primary_source: self, secondary_source: child_input)

        self
      end

      # @private
      # Merge this input with an input from a configuration. Fields defined in
      # the configuration take precedence over those defined on this input.
      def merge(other_input, merge_all: false)
        return self if other_input.nil?

        attributes_to_merge = merge_all ? ATTRIBUTES : MERGEABLE_ATTRIBUTES

        attributes_to_merge.each do |attribute|
          merge_attribute(attribute, primary_source: other_input, secondary_source: self)
        end

        self.type = other_input.type if other_input.type.present? && other_input.type != 'text'

        merge_options(primary_source: other_input, secondary_source: self)

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

      # @private
      # Merge input options. This performs a normal merge for all options except
      # for the "components" field, the members of which are individually merged
      # by `merge_components`
      # @param primary_source [Input]
      # @param secondary_source [Input]
      def merge_options(primary_source:, secondary_source:)
        primary_options = primary_source.options.dup || {}
        secondary_options = secondary_source.options.dup || {}

        return if primary_options.blank? && secondary_options.blank?

        primary_components = primary_options.delete(:components) || []
        secondary_components = secondary_options.delete(:components) || []

        send('options=', secondary_options.merge(primary_options))

        merge_components(primary_components:, secondary_components:)
      end

      # @private
      # Merge component hashes.
      # @param primary_source [Input]
      # @param secondary_source [Input]
      def merge_components(primary_components:, secondary_components:) # rubocop:disable Metrics/CyclomaticComplexity
        primary_components
          .each { |component| component[:name] = component[:name].to_sym }
        secondary_components
          .each { |component| component[:name] = component[:name].to_sym }

        return if primary_components.blank? && secondary_components.blank?

        component_keys =
          (primary_components + secondary_components)
            .map { |component| component[:name] }
            .uniq

        merged_components = component_keys.map do |key|
          primary_component = primary_components.find { |component| component[:name] == key }
          secondary_component = secondary_components.find { |component| component[:name] == key }

          next secondary_component if primary_component.blank?

          next primary_component if secondary_component.blank?

          Input.new(**secondary_component).merge(Input.new(**primary_component), merge_all: true).to_hash
        end

        merged_components.each { |component| component[:name] = component[:name].to_sym }

        self.options ||= {}
        self.options[:components] = merged_components
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
