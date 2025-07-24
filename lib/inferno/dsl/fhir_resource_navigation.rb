require_relative 'primitive_type'

module Inferno
  module DSL
    # The FHIRResourceNavigation module is used to pick values from a FHIR resource, based on a profile.
    # Originally intended for use for verifying the presence of Must Support elements on a resource.
    # This module expects pre-processed metadata defining the elements of the profile
    #  to be present in the attribute `metadata` in the including class.
    # @see Inferno::DSL::MustSupportMetadataExtractor
    module FHIRResourceNavigation
      DAR_EXTENSION_URL = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'.freeze
      PRIMITIVE_DATA_TYPES = FHIR::PRIMITIVES.keys

      # Get a value from the given FHIR element(s) by walking the given path through the element.
      # @param elements [FHIR::Model, Array<FHIR::Model>]
      # @param path [String]
      # @return [Array<FHIR::Model>]
      def resolve_path(elements, path)
        elements = Array.wrap(elements)
        return elements if path.blank?

        paths = path.split(/(?<!hl7)\./)
        segment = paths.first
        remaining_path = paths.drop(1).join('.')

        elements.flat_map do |element|
          child = get_next_value(element, segment)
          resolve_path(child, remaining_path)
        end.compact
      end

      # Get a value from the given FHIR element(s), by navigating through the resource to the given path.
      # Fields with a DataAbsentReason extension present may be selected if include_dar is true.
      # To filter the resulting elements, a block may be passed in.
      # @param given_element [FHIR::Model, Array<FHIR::Model>]
      # @param path [String]
      # @param include_dar [Boolean]
      # @return [Array<FHIR::Model>]
      def find_a_value_at(given_element, path, include_dar: false, &block)
        return nil if given_element.nil?

        elements = Array.wrap(given_element)
        return find_in_elements(elements, include_dar:, &block) if path.empty?

        path_segments = path.split(/(?<!hl7)\./)

        segment = path_segments.shift.delete_suffix('[x]').gsub(/^class$/, 'local_class').gsub('[x]:', ':').to_sym

        remaining_path = path_segments.join('.')
        elements.each do |element|
          child = get_next_value(element, segment)
          element_found = find_a_value_at(child, remaining_path, include_dar:, &block)
          return element_found if element_found.present? || element_found == false
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
        extension_url = property[/(?<=where\(url=').*(?='\))/]
        if extension_url.present?
          element.url == extension_url ? element : nil
        elsif property.to_s.include?(':') && !property.to_s.include?('url')
          find_slice_via_discriminator(element, property)

        else
          local_name = local_field_name(property)
          value = element.send(local_name)
          primitive_value = get_primitive_type_value(element, property, value)
          primitive_value.present? ? primitive_value : value
        end
      rescue NoMethodError
        nil
      end

      # @private
      def get_primitive_type_value(element, property, value)
        source_value = element.source_hash["_#{property}"]

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
      def find_slice_via_discriminator(element, property)
        return unless metadata.present?

        element_name = local_field_name(property.to_s.split(':')[0])
        slice_name = local_field_name(property.to_s.split(':')[1])

        slice_by_name = metadata.must_supports[:slices].find { |slice| slice[:slice_name] == slice_name }
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
        values = discriminator[:values].map { |value| value.merge(path: value[:path].split('.')) }
        verify_slice_by_values(slice, values)
      end

      # @private
      def matching_type_slice?(slice, discriminator)
        case discriminator[:code]
        when 'Date'
          begin
            Date.parse(slice)
          rescue ArgumentError
            false
          end
        when 'DateTime'
          begin
            DateTime.parse(slice)
          rescue ArgumentError
            false
          end
        when 'String'
          slice.is_a? String
        else
          slice.is_a? FHIR.const_get(discriminator[:code])
        end
      end

      # @private
      def matching_required_binding_slice?(slice, discriminator)
        slice_coding = discriminator[:path].present? ? slice.send((discriminator[:path]).to_s).coding : slice.coding
        slice_coding.any? do |coding|
          discriminator[:values].any? do |value|
            case value
            when String
              value == coding.code
            when Hash
              value[:system] == coding.system && value[:code] == coding.code
            end
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
          find_a_value_at(element, path_prefix) do |el_found|
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
