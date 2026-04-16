require_relative 'primitive_type'

module Inferno
  module DSL
    # The FHIRResourceNavigation module is used to pick values from a FHIR
    # resource, based on a profile. Originally intended for use for verifying
    # the presence of Must Support elements on a resource and finding values to
    # use for search parameters. The methods in this module related to slices
    # expects pre-processed metadata defining the elements of the profile to be
    # present in the attribute `metadata` in the including class.
    #
    # @see Inferno::DSL::MustSupportMetadataExtractor
    module FHIRResourceNavigation
      DAR_EXTENSION_URL = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'.freeze
      PRIMITIVE_DATA_TYPES = FHIR::PRIMITIVES.keys

      # Get a value from the given FHIR element(s) by walking the given path
      # through the element.
      #
      # @param elements [FHIR::Model, Array<FHIR::Model>]
      # @param path [String]
      # @return [Array<FHIR::Model>]
      def resolve_path(elements, path)
        elements = Array.wrap(elements)
        return elements if path.blank?

        paths = path_segments(path)
        segment = paths.first
        remaining_path = paths.drop(1).join('.')

        elements.flat_map do |element|
          child = get_next_value(element, segment)
          resolve_path(child, remaining_path)
        end.compact
      end

      # Get a value from the given FHIR element(s), by navigating through the
      # resource to the given path. Fields with a DataAbsentReason extension
      # present will be excluded unless include_dar is true. To filter the
      # resulting elements, a block may be passed in.
      #
      # @param given_element [FHIR::Model, Array<FHIR::Model>]
      # @param path [String]
      # @param include_dar [Boolean]
      # @return a single matching value (which can include `false`) or `nil` if not found
      def find_a_value_at(given_element, path, include_dar: false, &block)
        return nil if given_element.nil?

        elements = Array.wrap(given_element)
        return find_in_elements(elements, include_dar:, &block) if path.empty?

        path_segments = path_segments(path)

        segment = path_segments.shift

        remaining_path = path_segments.join('.')
        elements.each do |element|
          child = get_next_value(element, segment)
          element_found = find_a_value_at(child, remaining_path, include_dar:, &block)
          return element_found if value_not_empty?(element_found)
        end

        nil
      end

      # @private
      def find_in_elements(elements, include_dar: false, &)
        unless include_dar
          elements = elements.reject do |el|
            el.respond_to?(:extension) && el.extension.any? { |ext| ext.url == DAR_EXTENSION_URL }
          end
        end

        return elements.find(&) if block_given?

        elements.first
      end

      # @private
      def get_next_value(element, property)
        property = property.to_s
        extension_url = property[/(?<=where\(url=').*(?='\))/]
        return extension_filter_value(element, extension_url) if extension_url.present?
        return sliced_choice_value(element, property) if sliced_choice_path?(property)
        return populated_choice_value(element, property) if choice_path?(property)
        return find_slice_via_discriminator(element, property) if slice_path?(property)

        field_value(element, property)
      rescue NoMethodError
        nil
      end

      # @private
      def extension_filter_value(element, extension_url)
        element.url == extension_url ? element : nil
      end

      # @private
      def sliced_choice_path?(property)
        property.include?('[x]:')
      end

      # @private
      def choice_path?(property)
        property.end_with?('[x]')
      end

      # @private
      def slice_path?(property)
        property.include?(':') && !property.include?('url')
      end

      # @private
      def sliced_choice_value(element, property)
        _choice_path, sliced_field = property.split(':', 2)
        field_value(element, sliced_field)
      end

      # @private
      def populated_choice_value(element, property)
        choice_prefix = property.delete_suffix('[x]')
        populated_field =
          Array.wrap(element.to_hash&.keys)
            .map(&:to_s)
            .find do |field_name|
              field_name.start_with?(choice_prefix) && value_not_empty?(field_value(element, field_name))
            end

        return nil if populated_field.blank?

        field_value(element, populated_field)
      end

      # @private
      def field_value(element, field_name)
        local_name = local_field_name(field_name)
        value = element.send(local_name)
        primitive_value = get_primitive_type_value(element, field_name, value)
        primitive_value.present? ? primitive_value : value
      end

      # @private
      def get_primitive_type_value(element, property, value)
        return nil unless element.respond_to?(:source_hash)

        source_hash = element.source_hash
        return nil unless source_hash.present?

        source_value = source_hash["_#{property}"]

        return nil unless source_value.present?

        primitive_value = PrimitiveType.new(source_value)
        primitive_value.value = value
        primitive_value
      end

      # @private
      def local_field_name(field_name)
        # fhir_models prepends fields whose names are reserved in ruby with "local_"
        # This should be used before `x.send(field_name)`
        if ['method', 'class'].include?(field_name.to_s)
          "local_#{field_name}"
        else
          field_name
        end
      end

      # @private
      def path_segments(path)
        state = { current_segment: +'', segments: [], parentheses_depth: 0, in_quotes: false }
        path.each_char { |char| update_path_segment_state(state, char) }
        state[:segments] << state[:current_segment] unless state[:current_segment].empty?
        state[:segments]
      end

      # @private
      def update_path_segment_state(state, char)
        case char
        when "'"
          state[:current_segment] << char
          state[:in_quotes] = !state[:in_quotes]
        when '('
          append_path_character(state, char, depth_change: 1)
        when ')'
          append_path_character(state, char, depth_change: -1)
        when '.'
          split_path_segment_or_append(state, char)
        else
          state[:current_segment] << char
        end
      end

      # @private
      def append_path_character(state, char, depth_change:)
        state[:current_segment] << char
        state[:parentheses_depth] += depth_change unless state[:in_quotes]
      end

      # @private
      def split_path_segment_or_append(state, char)
        if state[:parentheses_depth].zero? && !state[:in_quotes]
          state[:segments] << state[:current_segment].dup
          state[:current_segment].clear
        else
          state[:current_segment] << char
        end
      end

      # @private
      def find_slice_via_discriminator(element, property)
        return unless metadata.present?

        element_name = local_field_name(property.to_s.split(':')[0])
        slice_name = local_field_name(property.to_s.split(':')[1])

        slice_by_name = metadata.must_supports[:slices].find { |slice| slice[:slice_name] == slice_name }
        return nil if slice_by_name.blank?

        discriminator = slice_by_name[:discriminator]
        slices = Array.wrap(element.send(element_name))
        slices.find { |slice| matching_slice?(slice, discriminator) }
      end

      # @private
      def matching_slice?(slice, discriminator)
        case discriminator[:type]
        when 'patternCodeableConcept'
          matching_pattern_codeable_concept_slice?(slice, discriminator)
        when 'patternCoding'
          matching_pattern_coding_slice?(slice, discriminator)
        when 'patternIdentifier'
          matching_pattern_identifier_slice?(slice, discriminator)
        when 'value'
          matching_value_slice?(slice, discriminator)
        when 'type'
          matching_type_slice?(slice, discriminator)
        when 'requiredBinding'
          matching_required_binding_slice?(slice, discriminator)
        end
      end

      # @private
      def matching_pattern_codeable_concept_slice?(slice, discriminator)
        slice_value = discriminator[:path].present? ? slice.send((discriminator[:path]).to_s)&.coding : slice.coding
        slice_value&.any? do |coding|
          coding.code == discriminator[:code] && coding.system == discriminator[:system]
        end
      end

      # @private
      def matching_pattern_coding_slice?(slice, discriminator)
        slice_value = discriminator[:path].present? ? slice.send(discriminator[:path]) : slice
        slice_value&.code == discriminator[:code] && slice_value&.system == discriminator[:system]
      end

      # @private
      def matching_pattern_identifier_slice?(slice, discriminator)
        slice.system == discriminator[:system]
      end

      # @private
      def matching_value_slice?(slice, discriminator)
        values = discriminator[:values].map { |value| value.merge(path: path_segments(value[:path])) }
        verify_slice_by_values(slice, values)
      end

      # @private
      def matching_type_slice?(slice, discriminator)
        slice_value = resolve_path(slice, discriminator[:path]).first

        case discriminator[:code]
        when 'Date'
          begin
            Date.parse(slice_value)
          rescue ArgumentError
            false
          end
        when 'DateTime'
          begin
            DateTime.parse(slice_value)
          rescue ArgumentError
            false
          end
        when 'String'
          slice_value.is_a? String
        else
          slice_value.is_a? FHIR.const_get(discriminator[:code])
        end
      end

      # @private
      def matching_required_binding_slice?(slice, discriminator)
        slice_coding = required_binding_codings(slice, discriminator)
        slice_coding.any? { |coding| required_binding_value_match?(coding, discriminator[:values]) }
      end

      # @private
      def required_binding_codings(slice, discriminator)
        if discriminator[:path].present?
          Array.wrap(resolve_path(slice, discriminator[:path])).flat_map { |value| Array.wrap(value&.coding) }
        elsif slice.is_a?(FHIR::Coding)
          [slice]
        else
          Array.wrap(slice.coding)
        end
      end

      # @private
      def required_binding_value_match?(coding, values)
        values.any? do |value|
          case value
          when String
            value == coding.code
          when Hash
            value[:system] == coding.system && value[:code] == coding.code
          end
        end
      end

      # @private
      def verify_slice_by_values(element, value_definitions)
        path_prefixes = value_definitions.map { |value_definition| value_definition[:path].first }.uniq
        path_prefixes.all? do |path_prefix|
          value_definitions_for_path =
            value_definitions
              .select { |value_definition| value_definition[:path].first == path_prefix }
              .each { |value_definition| value_definition[:path].shift }
          value_at_path_matches?(element, path_prefix) do |el_found|
            current_and_child_values_match?(el_found, value_definitions_for_path)
          end
        end
      end

      # @private
      def current_and_child_values_match?(el_found, value_definitions_for_path)
        child_element_value_definitions, current_element_value_definitions =
          value_definitions_for_path.partition { |value_definition| value_definition[:path].present? }

        current_element_values_match =
          current_element_value_definitions
            .all? { |value_definition| value_definition[:value] == el_found }

        child_element_values_match =
          if child_element_value_definitions.present?
            verify_slice_by_values(el_found, child_element_value_definitions)
          else
            true
          end
        current_element_values_match && child_element_values_match
      end

      # @private
      def value_at_path_matches?(element, path, include_dar: false, &)
        value_found = find_a_value_at(element, path, include_dar:, &)
        value_not_empty?(value_found)
      end

      # @private
      def value_not_empty?(value)
        value.present? || value == false
      end

      # @private
      def flatten_bundles(resources)
        resources.flat_map do |resource|
          if resource&.resourceType == 'Bundle'
            # Recursive to consider that Bundles may contain Bundles
            flatten_bundles(resource.entry.map(&:resource))
          else
            resource
          end
        end
      end
    end
  end
end
