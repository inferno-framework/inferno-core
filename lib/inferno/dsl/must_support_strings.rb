module Inferno
  module DSL
    # Builds the strings used to identify Must Support elements, slices, and extensions from their
    # metadata, so that lists of what is expected to be supported (eg {ProfileMetadata#must_support_strings})
    # and lists of what is missing (eg {MustSupportAssessment#missing_must_support_elements}) agree.
    #
    # Each item is represented by its ElementDefinition id (which includes the names of any parent
    # slices) without the leading resource type, eg 'category:us-core' rather than
    # 'Condition.category:us-core'. Elements with a fixed value have it appended, eg 'name.use = old'.
    # @private
    module MustSupportStrings
      module_function

      # @param element_definition [Hash] Must Support element metadata
      # @return [String]
      def element_string(element_definition)
        path = element_display_path(element_definition)

        fixed_value = element_definition[:fixed_value]
        if fixed_value.present? || fixed_value == false
          "#{path} = #{fixed_value}"
        else
          path
        end
      end

      # @param slice_definition [Hash] Must Support slice metadata
      # @return [String]
      def slice_string(slice_definition)
        id_string(slice_definition, :slice_id)
      end

      # @param extension_definition [Hash] Must Support extension metadata
      # @return [String]
      def extension_string(extension_definition)
        id_string(extension_definition, :id)
      end

      # Elements under a choice type slice (eg value[x]:valueQuantity.value) have their navigation
      # path rewritten so the slice name is mangled (eg valueQuantity:valueQuantity.value), so report
      # the original path instead. Elements where only some types of a choice are Must Support
      # (eg original path effective[x], path effectiveDateTime) keep their path since it names the type.
      def element_display_path(element_definition)
        original_path = element_definition[:original_path]
        original_path&.include?('[x]:') ? original_path : element_definition[:path]
      end

      def id_string(definition, id_key)
        id = definition[id_key]
        raise ArgumentError, "Must Support metadata is missing #{id_key.inspect}: #{definition.inspect}" if id.blank?

        without_resource_type(id)
      end

      # Resource types are PascalCase while element names are camelCase, so a leading
      # capitalized segment is the resource type prefix of an ElementDefinition id.
      def without_resource_type(id)
        id&.sub(/\A[A-Z][A-Za-z0-9]*\./, '')
      end
    end
  end
end
