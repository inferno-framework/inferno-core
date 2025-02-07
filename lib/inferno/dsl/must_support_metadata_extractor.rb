require_relative 'value_extractor'

module Inferno
  module DSL
    # The MustSupportMetadataExtractor takes a StructureDefinition and parses it into a hash-based metadata
    #  that simplifies checking for MustSupport elements.
    # MustSupport elements may be either plain elements, extensions, or slices.
    # This logic was originally developed for the US Core Test Kit and has been migrated into Inferno core.
    class MustSupportMetadataExtractor
      attr_accessor :profile_elements, :profile, :resource, :ig_resources, :requirement_extension_url

      # Construct a new extractor
      # @param profile_elements [Array<FHIR::ElementDefinition>] the elements of the profile to consider,
      #   ie, profile.snapshot.element
      # @param profile [FHIR::StructureDefinition] the profile to parse
      # @param resource [String] the resourceType that the profile applies to, ie, profile.type
      # @param ig_resources [Inferno::Entities::IG]
      # @param requirement_extension_url [String] the URL of an extension to flag elements as required even if not MS
      def initialize(profile_elements, profile, resource, ig_resources, requirement_extension_url = nil)
        self.profile_elements = profile_elements
        self.profile = profile
        self.resource = resource
        self.ig_resources = ig_resources
        self.requirement_extension_url = requirement_extension_url
      end

      # Retrieval method for the must support metadata
      # @return [Hash]
      def must_supports
        @must_supports ||= {
          extensions: must_support_extensions,
          slices: must_support_slices,
          elements: must_support_elements
        }
      end

      def by_requirement_extension_only?(element)
        requirement_extension_url && !element.mustSupport &&
          element.extension.any? do |extension|
            extension.url == requirement_extension_url && extension.valueBoolean
          end
      end

      def all_must_support_elements
        profile_elements.select { |element| element.mustSupport || by_requirement_extension_only?(element) }
      end

      def must_support_extension_elements
        all_must_support_elements.select { |element| element.path.end_with? 'extension' }
      end

      def must_support_extensions
        must_support_extension_elements.map do |element|
          {
            id: element.id,
            path: element.path.gsub("#{resource}.", ''),
            url: element.type.first.profile.first
          }.tap do |metadata|
            metadata[:by_requirement_extension_only] = true if by_requirement_extension_only?(element)
          end
        end
      end

      def must_support_slice_elements
        all_must_support_elements.select do |element|
          !element.path.end_with?('extension') && element.sliceName.present?
        end
      end

      def sliced_element(slice)
        profile_elements.find do |element|
          element.id == slice.path || element.id == slice.id.sub(":#{slice.sliceName}", '')
        end
      end

      def discriminators(slice)
        slice&.slicing&.discriminator
      end

      def find_element_by_discriminator_path(current_element, discriminator_path)
        if discriminator_path.present?
          profile_elements.find { |element| element.id == "#{current_element.id}.#{discriminator_path}" } ||
            profile_elements.find { |element| element.id == "#{current_element.path}.#{discriminator_path}" }
        else
          current_element
        end
      end

      def save_pattern_slice(pattern_element, discriminator_path, metadata)
        if pattern_element.patternCodeableConcept
          {
            type: 'patternCodeableConcept',
            path: discriminator_path,
            code: pattern_element.patternCodeableConcept.coding.first.code,
            system: pattern_element.patternCodeableConcept.coding.first.system
          }
        elsif pattern_element.patternCoding
          {
            type: 'patternCoding',
            path: discriminator_path,
            code: pattern_element.patternCoding.code,
            system: pattern_element.patternCoding.system
          }
        elsif pattern_element.patternIdentifier
          {
            type: 'patternIdentifier',
            path: discriminator_path,
            system: pattern_element.patternIdentifier.system
          }
        elsif required_binding_pattern?(pattern_element)
          {
            type: 'requiredBinding',
            path: discriminator_path,
            values: extract_required_binding_values(pattern_element, metadata)
          }
        else
          # prevent errors in case an IG does something different
          {
            type: 'unsupported',
            path: discriminator_path
          }
        end
      end

      def required_binding_pattern?(pattern_element)
        pattern_element.binding&.strength == 'required' && pattern_element.binding&.valueSet
      end

      def extract_required_binding_values(pattern_element, metadata)
        value_extractor = ValueExtractor.new(ig_resources, resource, profile_elements)

        value_extractor.codings_from_value_set_binding(pattern_element).presence ||
          value_extractor.values_from_resource_metadata([metadata[:path]]).presence || []
      end

      def must_support_type_slice_elements
        must_support_slice_elements.select do |element|
          discriminators(sliced_element(element))&.first&.type == 'type'
        end
      end

      def discriminator_path(discriminator)
        if discriminator.path == '$this'
          ''
        elsif discriminator.path.start_with?('$this.')
          discriminator.path[6..]
        else
          discriminator.path
        end
      end

      def type_slices
        must_support_type_slice_elements.map do |current_element|
          discriminator = discriminators(sliced_element(current_element)).first
          type_path = discriminator_path(discriminator)
          type_element = find_element_by_discriminator_path(current_element, type_path)

          type_code = type_element.type.first.code

          {
            slice_id: current_element.id,
            slice_name: current_element.sliceName,
            path: current_element.path.gsub("#{resource}.", ''),
            discriminator: {
              type: 'type',
              code: type_code.upcase_first
            }
          }.tap do |metadata|
            metadata[:by_requirement_extension_only] = true if by_requirement_extension_only?(current_element)
          end
        end
      end

      def must_support_value_slice_elements
        must_support_slice_elements.select do |element|
          # discriminator type 'pattern' is deprecated in FHIR R5 and made equivalent to 'value'
          ['value', 'pattern'].include?(discriminators(sliced_element(element))&.first&.type)
        end
      end

      def value_slices # rubocop:disable Metrics/CyclomaticComplexity
        must_support_value_slice_elements.map do |current_element|
          {
            slice_id: current_element.id,
            slice_name: current_element.sliceName,
            path: current_element.path.gsub("#{resource}.", '')
          }.tap do |metadata|
            fixed_values = []
            pattern_value = {}

            element_discriminators = discriminators(sliced_element(current_element))

            element_discriminators.each do |discriminator|
              discriminator_path = discriminator_path(discriminator)
              pattern_element = find_element_by_discriminator_path(current_element, discriminator_path)

              # This is a workaround for a known version of a profile that has a bad discriminator:
              # the discriminator refers to a nested field within a CodeableConcept,
              # but the profile doesn't contain an element definition for it, so there's no way to
              # define a fixed value on the element to define the slice.
              # In this instance the element has a second (good) discriminator on the CodeableConcept field itself,
              # and in subsequent versions of the profile, the bad discriminator was removed.
              next if pattern_element.nil? && element_discriminators.length > 1

              if pattern_element.fixed.present?
                fixed_values << {
                  path: discriminator_path,
                  value: pattern_element.fixed
                }
              elsif pattern_value.present?
                raise StandardError, "Found more than one pattern slices for the same element #{pattern_element}."
              else
                pattern_value = save_pattern_slice(pattern_element, discriminator_path, metadata)
              end
            end

            if fixed_values.present?
              metadata[:discriminator] = {
                type: 'value',
                values: fixed_values
              }
            elsif pattern_value.present?
              metadata[:discriminator] = pattern_value
            end

            metadata[:by_requirement_extension_only] = true if by_requirement_extension_only?(current_element)
          end
        end
      end

      def must_support_slices
        type_slices + value_slices
      end

      def plain_must_support_elements
        all_must_support_elements - must_support_extension_elements - must_support_slice_elements
      end

      def element_part_of_slice_discrimination?(element)
        must_support_slice_elements.any? { |ms_slice| element.id.include?(ms_slice.id) }
      end

      def handle_fixed_values(metadata, element)
        if element.fixed.present?
          metadata[:fixed_value] = element.fixed
        elsif element.patternCodeableConcept.present? && !element_part_of_slice_discrimination?(element)
          metadata[:fixed_value] = element.patternCodeableConcept.coding.first.code
          metadata[:path] += '.coding.code'
        elsif element.fixedCode.present?
          metadata[:fixed_value] = element.fixedCode
        elsif element.patternIdentifier.present? && !element_part_of_slice_discrimination?(element)
          metadata[:fixed_value] = element.patternIdentifier.system
          metadata[:path] += '.system'
        end
      end

      def type_must_support_extension?(extensions)
        extensions&.any? do |extension|
          extension.url == 'http://hl7.org/fhir/StructureDefinition/elementdefinition-type-must-support' &&
            extension.valueBoolean
        end
      end

      def save_type_code?(type)
        type.code == 'Reference'
      end

      def get_type_must_support_metadata(current_metadata, current_element)
        current_element.type.map do |type|
          next unless type_must_support_extension?(type.extension)

          metadata =
            {
              path: "#{current_metadata[:path].delete_suffix('[x]')}#{type.code.upcase_first}",
              original_path: current_metadata[:path]
            }
          metadata[:types] = [type.code] if save_type_code?(type)
          handle_type_must_support_target_profiles(type, metadata) if type.code == 'Reference'

          metadata
        end.compact
      end

      def handle_type_must_support_target_profiles(type, metadata)
        target_profiles = extract_target_profiles(type)

        # remove target_profile for FHIR Base resource type.
        target_profiles.delete_if { |reference| reference.start_with?('http://hl7.org/fhir/StructureDefinition') }
        metadata[:target_profiles] = target_profiles if target_profiles.present?
      end

      def extract_target_profiles(type)
        target_profiles = []

        if type.targetProfile&.length == 1
          target_profiles << type.targetProfile.first
        else
          type.source_hash['_targetProfile']&.each_with_index do |hash, index|
            if hash.present?
              element = FHIR::Element.new(hash)
              target_profiles << type.targetProfile[index] if type_must_support_extension?(element.extension)
            end
          end
        end

        target_profiles
      end

      def handle_choice_type_in_sliced_element(current_metadata, must_support_elements_metadata)
        choice_element_metadata = must_support_elements_metadata.find do |metadata|
          metadata[:original_path].present? &&
            current_metadata[:path].include?(metadata[:original_path])
        end

        return unless choice_element_metadata.present?

        current_metadata[:original_path] = current_metadata[:path]
        current_metadata[:path] =
          current_metadata[:path].sub(choice_element_metadata[:original_path], choice_element_metadata[:path])
      end

      def must_support_elements
        must_support_elements_metadata = []
        plain_must_support_elements.each do |current_element|
          current_metadata = {
            path: current_element.id.gsub("#{resource}.", '')
          }
          current_metadata[:by_requirement_extension_only] = true if by_requirement_extension_only?(current_element)

          type_must_support_metadata = get_type_must_support_metadata(current_metadata, current_element)

          if type_must_support_metadata.any?
            must_support_elements_metadata.concat(type_must_support_metadata)
          else
            handle_choice_type_in_sliced_element(current_metadata, must_support_elements_metadata)

            supported_types = extract_supported_types(current_element)
            current_metadata[:types] = supported_types if supported_types.present?

            if current_element.type.first&.code == 'Reference'
              handle_type_must_support_target_profiles(current_element.type.first,
                                                       current_metadata)
            end

            handle_fixed_values(current_metadata, current_element)

            remove_conflicting_metadata_without_fixed_value(must_support_elements_metadata, current_metadata)

            must_support_elements_metadata << current_metadata
          end
        end
        must_support_elements_metadata.uniq
      end

      def extract_supported_types(current_element)
        current_element.type.select { |type| save_type_code?(type) }.map(&:code)
      end

      def remove_conflicting_metadata_without_fixed_value(must_support_elements_metadata, current_metadata)
        must_support_elements_metadata.delete_if do |metadata|
          metadata[:path] == current_metadata[:path] && metadata[:fixed_value].blank?
        end
      end
    end
  end
end
