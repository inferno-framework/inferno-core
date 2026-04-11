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
        all_must_support_elements.select { |element| element.path.end_with? 'xtension' }
      end

      def must_support_extensions
        must_support_extension_elements.map do |element|
          {
            id: element.id,
            path: element.path.gsub("#{resource}.", ''),
            url: canonical_url_without_version(element.type.first.profile.first),
            modifier_extension: element.path.end_with?('modifierExtension')
          }.tap do |metadata|
            metadata[:by_requirement_extension_only] = true if by_requirement_extension_only?(element)
          end
        end
      end

      def canonical_url_without_version(url)
        url&.split('|')&.first
      end

      def must_support_slice_elements
        profile_elements.select do |element|
          next false if element.sliceName.blank? || element.path.end_with?('xtension')

          all_must_support_elements.include?(element) || slice_has_must_support_descendants?(element)
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

      def slice_has_must_support_descendants?(slice)
        all_must_support_elements.any? do |element|
          element.id.start_with?("#{slice.id}.")
        end
      end

      def find_element_by_discriminator_path(current_element, discriminator_path)
        target_element = current_element
        remaining_path = discriminator_path

        while remaining_path.present?
          target_element, remaining_path = take_discriminator_step(target_element, remaining_path)
          return nil if target_element.nil?
        end

        target_element
      end

      def take_discriminator_step(current_element, path)
        return take_extension_discriminator_step(current_element, path) if extension_discriminator_step?(path)

        take_standard_discriminator_step(current_element, path)
      end

      def extension_discriminator_step?(path)
        path.start_with?('extension(') || path.start_with?('modifierExtension(')
      end

      def take_extension_discriminator_step(current_element, path)
        extension_type = path.start_with?('modifierExtension(') ? 'modifierExtension' : 'extension'
        ext_url, remaining_path = path.delete_prefix("#{extension_type}('").split("')", 2)
        next_element = profile_elements.find do |element|
          element.path == "#{current_element.path}.#{extension_type}" &&
            element.id.start_with?("#{current_element.id}.#{extension_type}:") &&
            element.type.any? { |type| extension_profile_matches?(type, ext_url) }
        end

        [next_element, remaining_path&.delete_prefix('.')]
      end

      def extension_profile_matches?(type, ext_url)
        type.code == 'Extension' && type.profile.any? { |profile| profile.start_with?(ext_url) }
      end

      def take_standard_discriminator_step(current_element, path)
        step_path, remaining_path = path.split('.', 2)
        if remaining_path&.start_with?('ofType(')
          return take_choice_discriminator_step(current_element, step_path, remaining_path)
        end
        if legacy_choice_discriminator_step?(step_path)
          return take_legacy_choice_discriminator_step(current_element, step_path, remaining_path)
        end

        next_element =
          profile_elements.find { |element| element.id == "#{current_element.id}.#{step_path}" } ||
          profile_elements.find { |element| element.id == "#{current_element.path}.#{step_path}" }

        [next_element, remaining_path&.delete_prefix('.')]
      end

      def legacy_choice_discriminator_step?(path)
        path.match?(/\A.+\s+as\s+[[:word:]]+\z/)
      end

      def take_choice_discriminator_step(current_element, step_path, remaining_path)
        target_element = "#{step_path}[x]"
        target_type, remaining_path = remaining_path.delete_prefix('ofType(').split(')', 2)
        next_element = profile_elements.find do |element|
          element.id == "#{current_element.id}.#{target_element}" &&
            element.type.any? { |type| type.code.casecmp?(target_type) }
        end

        [next_element, remaining_path&.delete_prefix('.')]
      end

      def take_legacy_choice_discriminator_step(current_element, step_path, remaining_path)
        target_element, target_type = step_path.split(/\s+as\s+/, 2)
        target_element = "#{target_element}[x]" unless target_element.end_with?('[x]')
        next_element = find_choice_element(current_element, target_element, target_type)

        [next_element, remaining_path&.delete_prefix('.')]
      end

      def find_choice_element(current_element, target_element, target_type)
        [current_element.id, current_element.path].filter_map do |base_path|
          profile_elements.find do |element|
            element_matches_choice_type?(element, "#{base_path}.#{target_element}", target_type)
          end
        end.first
      end

      def element_matches_choice_type?(element, target_path, target_type)
        [element.id, element.path].include?(target_path) &&
          element.type.any? { |type| type.code.casecmp?(target_type) }
      end

      def save_pattern_slice(pattern_element, discriminator_path, metadata)
        runtime_path = navigation_compatible_discriminator_path(discriminator_path)

        if pattern_element.patternCodeableConcept
          {
            type: 'patternCodeableConcept',
            path: runtime_path,
            code: pattern_element.patternCodeableConcept.coding.first.code,
            system: pattern_element.patternCodeableConcept.coding.first.system
          }
        elsif pattern_element.patternCoding
          {
            type: 'patternCoding',
            path: runtime_path,
            code: pattern_element.patternCoding.code,
            system: pattern_element.patternCoding.system
          }
        elsif pattern_element.patternIdentifier
          {
            type: 'patternIdentifier',
            path: runtime_path,
            system: pattern_element.patternIdentifier.system
          }
        elsif required_binding_pattern?(pattern_element)
          {
            type: 'requiredBinding',
            path: runtime_path,
            values: extract_required_binding_values(pattern_element, metadata)
          }
        else
          # prevent errors in case an IG does something different
          {
            type: 'unsupported',
            path: runtime_path
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

      def navigation_compatible_discriminator_path(discriminator_path)
        normalized_path = discriminator_path&.gsub(/(modifierExtension|extension)\('([^']+)'\)/, "\\1.where(url='\\2')")
        normalized_path = normalized_path&.gsub(/([[:word:]\[\]]+)\.ofType\(([^)]+)\)/) do
          "#{Regexp.last_match(1).delete_suffix('[x]')}#{Regexp.last_match(2).upcase_first}"
        end
        normalized_path&.gsub(/([[:word:]\[\]]+)\s+as\s+([[:word:]]+)/) do
          "#{Regexp.last_match(1).delete_suffix('[x]')}#{Regexp.last_match(2).upcase_first}"
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
          discriminator_metadata = {
            type: 'type',
            code: type_code.upcase_first
          }
          runtime_path = navigation_compatible_discriminator_path(type_path)
          discriminator_metadata[:path] = runtime_path if runtime_path.present?

          {
            slice_id: current_element.id,
            slice_name: current_element.sliceName,
            path: current_element.path.gsub("#{resource}.", ''),
            discriminator: discriminator_metadata
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

              if pattern_element.nil?
                pattern_value = {
                  type: 'unsupported',
                  path: navigation_compatible_discriminator_path(discriminator_path)
                }
              elsif value_not_empty?(pattern_element.fixed)
                fixed_values << {
                  path: navigation_compatible_discriminator_path(discriminator_path),
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

      def value_not_empty?(value)
        value.present? || value == false
      end

      def handle_fixed_values(metadata, element)
        if value_not_empty?(element.fixed)
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
