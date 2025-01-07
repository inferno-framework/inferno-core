module Inferno
  module DSL
    class ValueExtractor
      attr_accessor :ig_resources, :resource, :profile_elements

      def initialize(ig_resources, resource, profile_elements)
        self.ig_resources = ig_resources
        self.resource = resource
        self.profile_elements = profile_elements
      end

      def values_from_fixed_codes(profile_element, type)
        return [] unless type == 'CodeableConcept'

        elements = profile_elements.select do |element|
          element.path == "#{profile_element.path}.coding.code" && element.fixedCode.present?
        end

        elements.map(&:fixedCode)
      end

      def values_from_pattern_coding(profile_element, type)
        return [] unless type == 'CodeableConcept'

        elements = profile_elements.select do |element|
          element.path == "#{profile_element.path}.coding" && element.patternCoding.present?
        end

        elements.map { |element| element.patternCoding.code }
      end

      def values_from_pattern_codeable_concept(profile_element, type)
        return [] unless type == 'CodeableConcept'

        elements = profile_elements.select do |element|
          element.path == profile_element.path && element.patternCodeableConcept.present? && element.min.positive?
        end

        elements.map { |element| element.patternCodeableConcept.coding.first.code }
      end

      def value_set_binding(the_element)
        the_element&.binding
      end

      def value_set(the_element)
        ig_resources.value_set_by_url(value_set_binding(the_element)&.valueSet)
      end

      def bound_systems(the_element)
        bound_systems_from_valueset(value_set(the_element))
      end

      def bound_systems_from_valueset(value_set)
        value_set&.compose&.include&.map do |include_element|
          bound_systems_from_valueset_include_element(include_element)
        end&.flatten&.compact
      end

      def bound_systems_from_valueset_include_element(include_element)
        if include_element.concept.present?
          include_element
        elsif include_element.system.present? && include_element.filter&.empty?
          # Cannot process intensional value set with filters
          ig_resources.code_system_by_url(include_element.system)
        elsif include_element.valueSet.present?
          include_element.valueSet.map do |vs|
            a_value_set = ig_resources.value_set_by_url(vs)
            bound_systems_from_valueset(a_value_set)
          end
        end
      end

      def codes_from_value_set_binding(the_element)
        codes_from_system_code_pair(codings_from_value_set_binding(the_element))
      end

      def codes_from_system_code_pair(codings)
        codings.present? ? codings.map { |coding| coding[:code] }.compact.uniq : []
      end

      def codings_from_value_set_binding(the_element)
        return [] if the_element.nil?

        bound_systems = bound_systems(the_element)

        return codings_from_bound_systems(bound_systems) if bound_systems.present?

        expansion_contains = value_set_expansion_contains(the_element)

        return [] if expansion_contains.blank?

        expansion_contains.map { |contains| { system: contains.system, code: contains.code } }.compact.uniq
      end

      def codings_from_bound_systems(bound_systems)
        return [] unless bound_systems.present?

        bound_systems.flat_map do |bound_system|
          case bound_system
          when FHIR::ValueSet::Compose::Include
            bound_system.concept.map { |concept| { system: bound_system.system, code: concept.code } }
          when FHIR::CodeSystem
            bound_system.concept.map { |concept| { system: bound_system.url, code: concept.code } }
          else
            []
          end
        end.uniq
      end

      def value_set_expansion_contains(element)
        value_set(element)&.expansion&.contains
      end

      def fhir_metadata(current_path)
        FHIR.const_get(resource)::METADATA[current_path]
      end

      def values_from_resource_metadata(paths)
        values = []

        paths.each do |current_path|
          current_metadata = fhir_metadata(current_path)

          next unless current_metadata&.dig('valid_codes').present?

          values += current_metadata['valid_codes'].flat_map do |system, codes|
            codes.map { |code| { system:, code: } }
          end
        end

        values
      end
    end
  end
end
