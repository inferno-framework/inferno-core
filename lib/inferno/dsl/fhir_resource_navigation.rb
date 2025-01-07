require_relative 'primitive_type'

module Inferno
  module DSL
    module FHIRResourceNavigation
      DAR_EXTENSION_URL = 'http://hl7.org/fhir/StructureDefinition/data-absent-reason'.freeze
      PRIMITIVE_DATA_TYPES = FHIR::PRIMITIVES.keys

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

      def find_a_value_at(given_element, path, include_dar: false, &block)
        return nil if given_element.nil?

        elements = Array.wrap(given_element)
        return find_in_elements(elements, include_dar:, &block) if path.empty?

        path_segments = path.split(/(?<!hl7)\./)

        segment = path_segments.shift.delete_suffix('[x]').gsub(/^class$/, 'local_class').gsub('[x]:', ':').to_sym
        # no_elements_present =
        #   elements.none? do |element|
        #     child = get_next_value(element, segment)
        #     child.present? || child == false
        #   end
        # return nil if no_elements_present

        remaining_path = path_segments.join('.')
        elements.each do |element|
          child = get_next_value(element, segment)
          element_found = find_a_value_at(child, remaining_path, include_dar:, &block)
          return element_found if element_found.present? || element_found == false
        end

        nil
      end

      def find_in_elements(elements, include_dar: false, &block)
        unless include_dar
          elements = elements.reject do |el|
            el.respond_to?(:extension) && el.extension.any? { |ext| ext.url == DAR_EXTENSION_URL }
          end
        end

        return elements.find(&block) if block_given?

        elements.first
      end

      def get_next_value(element, property)
        extension_url = property[/(?<=where\(url=').*(?='\))/]
        if extension_url.present?
          element.url == extension_url ? element : nil
        elsif property.to_s.include?(':') && !property.to_s.include?('url')
          find_slice_via_discriminator(element, property)

        else
          value = element.send(property)
          primitive_value = get_primitive_type_value(element, property, value)
          primitive_value.present? ? primitive_value : value
        end
      rescue NoMethodError
        nil
      end

      def get_primitive_type_value(element, property, value)
        source_value = element.source_hash["_#{property}"]

        return nil unless source_value.present?

        primitive_value = PrimitiveType.new(source_value)
        primitive_value.value = value
        primitive_value
      end

      def find_slice_via_discriminator(element, property)
        return unless metadata.present?

        element_name = property.to_s.split(':')[0].gsub(/^class$/, 'local_class')
        slice_name = property.to_s.split(':')[1].gsub(/^class$/, 'local_class')

        slice_by_name = metadata.must_supports[:slices].find { |slice| slice[:slice_name] == slice_name }
        discriminator = slice_by_name[:discriminator]
        slices = Array.wrap(element.send(element_name))
        slices.find { |slice| matching_slice?(slice, discriminator) }
      end

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

      def matching_pattern_codeable_concept_slice?(slice, discriminator)
        slice_value = discriminator[:path].present? ? slice.send((discriminator[:path]).to_s)&.coding : slice.coding
        slice_value&.any? do |coding|
          coding.code == discriminator[:code] && coding.system == discriminator[:system]
        end
      end

      def matching_pattern_coding_slice?(slice, discriminator)
        slice_value = discriminator[:path].present? ? slice.send(discriminator[:path]) : slice
        slice_value&.code == discriminator[:code] && slice_value&.system == discriminator[:system]
      end

      def matching_pattern_identifier_slice?(slice, discriminator)
        slice.identifier.system == discriminator[:system]
      end

      def matching_value_slice?(slice, discriminator)
        values = discriminator[:values].map { |value| value.merge(path: value[:path].split('.')) }
        verify_slice_by_values(slice, values)
      end

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

      def matching_required_binding_slice?(slice, discriminator)
        discriminator[:path].present? ? slice.send((discriminator[:path]).to_s).coding : slice.coding
        slice_value { |coding| discriminator[:values].include?(coding.code) }
      end

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
    end
  end
end
