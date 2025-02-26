module Inferno
  module DSL
    module MustSupportTest
      def perform_test(resources)
        missing_elements(resources)
        missing_slices(resources)
        missing_extensions(resources)

        handle_must_support_choices if metadata.must_supports[:choices].present?

        missing_must_support_strings
      end

      def handle_must_support_choices
        handle_must_support_element_choices
        handle_must_support_extension_choices
        handle_must_support_slice_choices
      end

      def handle_must_support_element_choices
        missing_elements.delete_if do |element|
          choices = metadata.must_supports[:choices].find do |choice|
            choice[:paths]&.include?(element[:path]) ||
              choice[:elements]&.any? { |ms_element| ms_element[:path] == element[:path] }
          end
          any_choice_supported?(choices)
        end
      end

      def handle_must_support_extension_choices
        missing_extensions.delete_if do |extension|
          choices = metadata.must_supports[:choices].find do |choice|
            choice[:extension_ids]&.include?(extension[:id])
          end
          any_choice_supported?(choices)
        end
      end

      def handle_must_support_slice_choices
        missing_slices.delete_if do |slice|
          choices = metadata.must_supports[:choices].find { |choice| choice[:slice_names]&.include?(slice[:name]) }
          any_choice_supported?(choices)
        end
      end

      def any_choice_supported?(choices)
        return false unless choices.present?

        any_path_choice_supported?(choices) ||
          any_extension_ids_choice_supported?(choices) ||
          any_slice_names_choice_supported?(choices) ||
          any_elements_choice_supported?(choices)
      end

      def any_path_choice_supported?(choices)
        return false unless choices[:paths].present?

        choices[:paths].any? { |path| missing_elements.none? { |element| element[:path] == path } }
      end

      def any_extension_ids_choice_supported?(choices)
        return false unless choices[:extension_ids].present?

        choices[:extension_ids].any? do |extension_id|
          missing_extensions.none? { |extension| extension[:id] == extension_id }
        end
      end

      def any_slice_names_choice_supported?(choices)
        return false unless choices[:slice_names].present?

        choices[:slice_names].any? { |slice_name| missing_slices.none? { |slice| slice[:name] == slice_name } }
      end

      def any_elements_choice_supported?(choices)
        return false unless choices[:elements].present?

        choices[:elements].any? do |choice|
          missing_elements.none? do |element|
            element[:path] == choice[:path] && element[:fixed_value] == choice[:fixed_value]
          end
        end
      end

      def missing_must_support_strings
        missing_elements.map { |element_definition| missing_element_string(element_definition) } +
          missing_slices.map { |slice_definition| slice_definition[:slice_id] } +
          missing_extensions.map { |extension_definition| extension_definition[:id] }
      end

      def missing_element_string(element_definition)
        if element_definition[:fixed_value].present?
          "#{element_definition[:path]}:#{element_definition[:fixed_value]}"
        else
          element_definition[:path]
        end
      end

      def must_support_extensions
        metadata.must_supports[:extensions]
      end

      def missing_extensions(resources = [])
        @missing_extensions ||=
          must_support_extensions.select do |extension_definition|
            resources.none? do |resource|
              path = extension_definition[:path]

              if path == 'extension'
                resource.extension.any? { |extension| extension.url == extension_definition[:url] }
              else
                extension = find_a_value_at(resource, path) do |el|
                  el.url == extension_definition[:url]
                end

                extension.present?
              end
            end
          end
      end

      def must_support_elements
        metadata.must_supports[:elements]
      end

      def missing_elements(resources = [])
        @missing_elements ||= find_missing_elements(resources, must_support_elements)
      end

      def find_missing_elements(resources, must_support_elements)
        must_support_elements.select do |element_definition|
          resources.none? { |resource| resource_populates_element?(resource, element_definition) }
        end
      end

      def resource_populates_element?(resource, element_definition)
        path = element_definition[:path]
        ms_extension_urls = must_support_extensions.select { |ex| ex[:path] == "#{path}.extension" }
          .map { |ex| ex[:url] }

        value_found = find_a_value_at(resource, path) do |potential_value|
          matching_without_extensions?(potential_value, ms_extension_urls, element_definition[:fixed_value])
        end

        # Note that false.present? => false, which is why we need to add this extra check
        value_found.present? || value_found == false
      end

      def matching_without_extensions?(value, ms_extension_urls, fixed_value)
        if value.instance_of?(Inferno::DSL::PrimitiveType)
          urls = value.extension&.map(&:url)
          has_ms_extension = (urls & ms_extension_urls).present?
          value = value.value
        end

        return false unless has_ms_extension || value_without_extensions?(value)

        matches_fixed_value?(value, fixed_value)
      end

      def matches_fixed_value?(value, fixed_value)
        fixed_value.blank? || value == fixed_value
      end

      def value_without_extensions?(value)
        value_without_extensions = value.respond_to?(:to_hash) ? value.to_hash.except('extension') : value
        value_without_extensions.present? || value_without_extensions == false
      end

      def must_support_slices
        metadata.must_supports[:slices]
      end

      def missing_slices(resources = [])
        @missing_slices ||=
          must_support_slices.select do |slice|
            resources.none? do |resource|
              path = slice[:path]
              find_slice(resource, path, slice[:discriminator]).present?
            end
          end
      end

      def find_slice(resource, path, discriminator)
        # TODO: there is a lot of similarity
        # between this and FHIRResourceNavigation.matching_slice?
        # Can these be combined?
        find_a_value_at(resource, path) do |element|
          case discriminator[:type]
          when 'patternCodeableConcept'
            find_pattern_codeable_concept_slice(element, discriminator)
          when 'patternCoding'
            find_pattern_coding_slice(element, discriminator)
          when 'patternIdentifier'
            find_pattern_identifier_slice(element, discriminator)
          when 'value'
            find_value_slice(element, discriminator)
          when 'type'
            find_type_slice(element, discriminator)
          when 'requiredBinding'
            find_required_binding_slice(element, discriminator)
          end
        end
      end

      def find_pattern_codeable_concept_slice(element, discriminator)
        coding_path = discriminator[:path].present? ? "#{discriminator[:path]}.coding" : 'coding'
        find_a_value_at(element, coding_path) do |coding|
          coding.code == discriminator[:code] && coding.system == discriminator[:system]
        end
      end

      def find_pattern_coding_slice(element, discriminator)
        coding_path = discriminator[:path].present? ? discriminator[:path] : ''
        find_a_value_at(element, coding_path) do |coding|
          coding.code == discriminator[:code] && coding.system == discriminator[:system]
        end
      end

      def find_pattern_identifier_slice(element, discriminator)
        find_a_value_at(element, discriminator[:path]) do |identifier|
          identifier.system == discriminator[:system]
        end
      end

      def find_value_slice(element, discriminator)
        values = discriminator[:values].map { |value| value.merge(path: value[:path].split('.')) }
        find_slice_by_values(element, values)
      end

      def find_type_slice(element, discriminator)
        case discriminator[:code]
        when 'Date'
          begin
            Date.parse(element)
          rescue ArgumentError
            false
          end
        when 'DateTime'
          begin
            DateTime.parse(element)
          rescue ArgumentError
            false
          end
        when 'String'
          element.is_a? String
        else
          element.is_a? FHIR.const_get(discriminator[:code])
        end
      end

      def find_required_binding_slice(element, discriminator)
        coding_path = discriminator[:path].present? ? "#{discriminator[:path]}.coding" : 'coding'

        find_a_value_at(element, coding_path) do |coding|
          discriminator[:values].any? { |value| value[:system] == coding.system && value[:code] == coding.code }
        end
      end

      def find_slice_by_values(element, value_definitions)
        Array.wrap(element).find { |el| verify_slice_by_values(el, value_definitions) }
      end
    end
  end
end
