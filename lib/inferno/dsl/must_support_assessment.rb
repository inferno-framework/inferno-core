module Inferno
  module DSL
    # The MustSupportAssessment module contains the logic for tests
    # that check "All Must Support elements are present".
    # Generally, test authors should use `assert_must_support_elements_present`
    # or `missing_must_support_elements` DSL methods.
    # A few additional methods are exposed to support the transition of existing tests that
    # call into these methods directly.
    module MustSupportAssessment
      # Find any Must Support elements defined on the given profile that are missing in the given resources.
      # Must Support elements are identified on the profile StructureDefinition and pre-parsed into metadata,
      # which may be customized prior to the check by passing a block. Alternate metadata may be provided directly.
      # Set test suite config flag debug_must_support_metadata: true to log the metadata to a file for debugging.
      #
      # @param resources [Array<FHIR::Resource>]
      # @param profile_url [String]
      # @param validator_name [Symbol] Name of the FHIR Validator that references the IG the profile is in
      # @param metadata [Hash] MustSupport Metadata (optional),
      #        if provided the check will use this instead of re-generating metadata from the profile
      # @param requirement_extension [String] Extension URL that implies "required" as an alternative to the MS flag
      # @yield [Metadata] Customize the metadata before running the test
      # @return [Array<String>] List of missing elements
      def missing_must_support_elements(resources, profile_url, validator_name: :default, metadata: nil,
                                        requirement_extension: nil, &)
        debug_metadata = config.options[:debug_must_support_metadata]

        if metadata.present?
          InternalMustSupportLogic.new.perform_must_support_test_with_metadata(resources, metadata, debug_metadata:)
        else
          ig, profile = find_ig_and_profile(profile_url, validator_name)
          perform_must_support_assessment(profile, resources, ig, debug_metadata:, requirement_extension:, &)
        end
      end

      # Find any non-Must-Support elements that ARE present in the given resources.
      #
      # Implements the Da Vinci Burden Reduction conformance rules (CRD conf-10/13,
      # PAS conf-12) for client requests: a conforming client must not depend on
      # non-must-support elements, which we verify by ensuring it does not populate
      # them. Reports both populated non-MS elements and any extensions whose URLs
      # are not defined as must-support in the profile.
      #
      # The metadata schema mirrors {#missing_must_support_elements}: entries in
      # `must_supports[:elements]` are treated as non-MS when tagged with
      # `must_support: false`. Entries without the flag are assumed to be MS, which
      # preserves the behavior of existing metadata generated before this method
      # was added.
      #
      # @param resources [Array<FHIR::Resource>]
      # @param profile_url [String]
      # @param validator_name [Symbol]
      # @param metadata [Hash] Pre-built metadata (skips re-extraction)
      # @param requirement_extension [String]
      # @yield [Metadata] Customize the metadata before running the check
      # @return [Array<String>] non-MS element paths and unexpected extension URLs that were found
      def non_must_support_elements_present(resources, profile_url, validator_name: :default, metadata: nil,
                                            requirement_extension: nil, &)
        debug_metadata = config.options[:debug_must_support_metadata]

        if metadata.present?
          InternalMustSupportLogic.new
            .perform_non_must_support_check_with_metadata(resources, metadata, debug_metadata:)
        else
          ig, profile = find_ig_and_profile(profile_url, validator_name)
          test_impl = InternalMustSupportLogic.new
          profile_metadata = test_impl.extract_metadata(profile, ig, requirement_extension:)
          yield profile_metadata if block_given?

          test_impl.perform_non_must_support_check_with_metadata(resources, profile_metadata, debug_metadata:)
        end
      end

      # perform_must_support_assessment allows customizing the metadata with a block.
      # Customizing the metadata may add, modify, or remove items.
      # For instance, US Core 3.1.1 Patient "Previous Name" is defined as MS only in narrative.
      # Choices are also defined only in narrative.
      # @param profile [FHIR::StructureDefinition]
      # @param resources [Array<FHIR::Model>]
      # @param ig [Inferno::Entities::IG]
      # @param debug_metadata [Boolean] if true, write out the final metadata used to a temporary file
      # @param requirement_extension [String] Extension URL that implies "required" as an alternative to the MS flag
      # @yield [Metadata] Customize the metadata before running the test
      # @return [Array<String>] list of elements that were not found in the provided resources
      def perform_must_support_assessment(profile, resources, ig, debug_metadata: false, requirement_extension: nil)
        test_impl = InternalMustSupportLogic.new
        profile_metadata = test_impl.extract_metadata(profile, ig, requirement_extension:)
        yield profile_metadata if block_given?

        test_impl.perform_must_support_test_with_metadata(resources, profile_metadata, debug_metadata:)
      end

      def find_missing_elements(resources, must_support_elements)
        InternalMustSupportLogic.new(metadata).find_missing_elements(resources, must_support_elements)
      end

      def missing_element_string(element_definition)
        InternalMustSupportLogic.new.missing_element_string(element_definition)
      end

      # @private
      class InternalMustSupportLogic
        include FHIRResourceNavigation

        attr_accessor :metadata

        def initialize(metadata = nil)
          @metadata = metadata
        end

        # perform_must_support_test_with_metadata is invoked from check and perform_must_support_test,
        # with the metadata to be used as the basis for the test.
        # It may also be invoked directly from a test if you want to completely overwrite the metadata.
        # @param resources [Array<FHIR::Model>]
        # @param profile_metadata [Metadata] Metadata object with must_supports field
        # @param debug_metadata [Boolean] if true, write out the final metadata used to a temporary file
        # @return [Array<String>] list of elements that were not found in the provided resources
        def perform_must_support_test_with_metadata(resources, profile_metadata, debug_metadata: false)
          return if resources.blank?

          @metadata = profile_metadata

          write_metadata_for_debugging if debug_metadata

          perform_test(resources)
        end

        def extract_metadata(profile, ig, requirement_extension: nil)
          MustSupportMetadataExtractor.new(profile.snapshot.element, profile, profile.type, ig, requirement_extension)
        end

        def write_metadata_for_debugging
          outfile = "#{metadata.profile&.id}-#{SecureRandom.uuid}.yml"

          File.open(File.join(Dir.tmpdir, outfile), 'w') do |f|
            writable_metadata = { must_supports: @metadata.must_supports.to_hash }
            f.write(YAML.dump(writable_metadata))
            puts "Wrote MustSupport metadata to #{f.path}"
          end
        end

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

        # Run the non-must-support presence check (CRD conf-10/13, PAS conf-12).
        # If the metadata has no entries explicitly flagged as must_support: false,
        # the check is skipped entirely so that callers using pre-existing metadata
        # (which never carried non-MS entries) continue to behave as before.
        # @param resources [Array<FHIR::Model>]
        # @param profile_metadata [Metadata]
        # @param debug_metadata [Boolean]
        # @return [Array<String>] paths/URLs of non-MS elements or undefined extensions that were found
        def perform_non_must_support_check_with_metadata(resources, profile_metadata, debug_metadata: false)
          return [] if resources.blank?

          @metadata = profile_metadata

          write_metadata_for_debugging if debug_metadata

          return [] unless metadata_opts_into_non_must_support_check?

          present_non_must_support_elements(resources) + unexpected_extensions(resources)
        end

        # Metadata produced by the current extractor enumerates non-MS entries with
        # `must_support: false`. Older metadata (or metadata customized to suppress
        # the check) has no such entries, in which case we don't run the analysis.
        def metadata_opts_into_non_must_support_check?
          metadata.must_supports[:elements].any? { |element| element[:must_support] == false }
        end

        # @return [Array<String>] paths of non-MS elements found in any resource
        def present_non_must_support_elements(resources)
          present = non_must_support_elements.select do |element_definition|
            resources.any? { |resource| resource_populates_element?(resource, element_definition) }
          end
          present.map { |element_definition| missing_element_string(element_definition) }
        end

        # @return [Array<String>] URLs of extensions present on any resource that are
        #   not declared as must-support in the profile metadata. Recursively walks
        #   sibling/child FHIR elements, but does NOT recurse into the internal
        #   structure of an extension - sub-extensions of a complex extension belong
        #   to the parent extension's definition and would otherwise produce noise
        #   (e.g., `ombCategory` inside `us-core-race`).
        def unexpected_extensions(resources)
          allowed_urls = must_support_extensions.to_set { |extension| normalized_extension_url(extension[:url]) }

          resources.flat_map { |resource| collect_extension_urls(resource) }
            .uniq
            .reject { |url| allowed_urls.include?(normalized_extension_url(url)) }
        end

        def collect_extension_urls(element)
          return [] unless element.is_a?(FHIR::Model)

          urls = direct_extension_urls(element)

          non_extension_child_models(element).each do |child|
            urls.concat(collect_extension_urls(child))
          end

          urls
        end

        def direct_extension_urls(element)
          urls = []
          [:extension, :modifierExtension].each do |field|
            next unless element.respond_to?(field)

            Array.wrap(element.public_send(field)).each do |extension|
              urls << extension.url if extension.respond_to?(:url) && extension.url.present?
            end
          end
          urls
        end

        def non_extension_child_models(element)
          element.instance_variables.flat_map do |name|
            next [] if [:@extension, :@modifierExtension].include?(name)

            Array.wrap(element.instance_variable_get(name)).select do |value|
              value.is_a?(FHIR::Model) && !value.is_a?(FHIR::Extension)
            end
          end
        end

        def missing_element_string(element_definition)
          if element_definition[:fixed_value].present?
            "#{element_definition[:path]}:#{element_definition[:fixed_value]}"
          else
            element_definition[:path]
          end
        end

        def must_support_extensions
          metadata.must_supports[:extensions].reject { |extension| extension[:must_support] == false }
        end

        def missing_extensions(resources = [])
          @missing_extensions ||=
            must_support_extensions.select do |extension_definition|
              expected_url = normalized_extension_url(extension_definition[:url])

              resources.none? do |resource|
                path = extension_definition[:path]

                if path == 'extension'
                  Array.wrap(resource.extension).any? do |extension|
                    normalized_extension_url(extension.url) == expected_url
                  end
                else
                  extension = find_a_value_at(resource, path) do |el|
                    normalized_extension_url(el.url) == expected_url
                  end

                  extension.present?
                end
              end
            end
        end

        def must_support_elements
          metadata.must_supports[:elements].reject { |element| element[:must_support] == false }
        end

        def non_must_support_elements
          metadata.must_supports[:elements].select { |element| element[:must_support] == false }
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
          raw_path = element_definition[:path]
          path = navigation_compatible_must_support_path(raw_path)

          ms_extension_urls = must_support_extensions.select { |ex| ex[:path] == "#{raw_path}.extension" }
            .map { |ex| ex[:url] }

          value_found = find_a_value_at(resource, path) do |potential_value|
            matching_without_extensions?(potential_value, ms_extension_urls, element_definition[:fixed_value])
          end

          # Note that false.present? => false, which is why we need to add this extra check
          value_found.present? || value_found == false
        end

        def navigation_compatible_must_support_path(path)
          logical_segments = []

          path_segments(path).map do |segment|
            normalized_segment = normalized_must_support_path_segment(segment, logical_segments)
            logical_segments << segment.split(':').first
            normalized_segment
          end.join('.')
        end

        def normalized_must_support_path_segment(segment, logical_segments)
          extension_type, extension_name = segment.match(/\A(modifierExtension|extension):(.+)\z/)&.captures
          return segment if extension_type.blank?

          extension_path = [logical_segments.join('.'), extension_type].reject(&:blank?).join('.')
          extension_definition = must_support_extension_definition(extension_path, extension_type, extension_name)
          return segment if extension_definition.blank?

          "#{extension_type}.where(url='#{normalized_extension_url(extension_definition[:url])}')"
        end

        def must_support_extension_definition(extension_path, extension_type, extension_name)
          suffix = "#{extension_type}:#{extension_name}"
          path_matching_extensions = must_support_extensions.select { |definition| definition[:path] == extension_path }

          extension_definition_candidates(path_matching_extensions).each do |definitions, matcher|
            match = definitions.find { |definition| definition[:id].public_send(matcher, suffix) }
            return match if match.present?
          end

          nil
        end

        def extension_definition_candidates(path_matching_extensions)
          [
            [path_matching_extensions, :end_with?],
            [path_matching_extensions, :include?],
            [must_support_extensions, :end_with?]
          ]
        end

        def process_must_support_element_in_extension(resource, path)
          return [resource, path] unless path.start_with?('extension:')

          path_without_prefix = path.delete_prefix('extension:')
          extension_split = path_without_prefix.split('.')
          extension_name = extension_split.first
          extension_path = extension_split.last

          found_extension_url =
            normalized_extension_url(must_support_extensions.find { |ex| ex[:id].include?(extension_name) }[:url])
          ms_element_extension = resource.extension.find do |extension|
            normalized_extension_url(extension.url) == found_extension_url
          end

          if ms_element_extension.present?
            resource = ms_element_extension
            path = extension_path
          end

          [resource, path]
        end

        def matching_without_extensions?(value, ms_extension_urls, fixed_value)
          has_ms_extension = must_support_extension_present?(value, ms_extension_urls)

          value = value.value if value.instance_of?(Inferno::DSL::PrimitiveType)

          return false unless has_ms_extension || value_without_extensions?(value)

          matches_fixed_value?(value, fixed_value)
        end

        def must_support_extension_present?(value, ms_extension_urls)
          return false unless value.respond_to?(:extension)

          (extension_urls(value) & normalized_extension_urls(ms_extension_urls)).present?
        end

        def extension_urls(value)
          Array.wrap(value.extension).map { |extension| normalized_extension_url(extension.url) }
        end

        def normalized_extension_urls(urls)
          Array.wrap(urls).map { |url| normalized_extension_url(url) }
        end

        def normalized_extension_url(url)
          url&.split('|')&.first
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
          values = discriminator[:values].map { |value| value.merge(path: path_segments(value[:path])) }
          find_slice_by_values(element, values)
        end

        def find_type_slice(element, discriminator)
          case discriminator[:code]
          when 'Date'
            begin
              Date.parse(element)
            rescue ArgumentError, TypeError
              false
            end
          when 'DateTime'
            begin
              DateTime.parse(element)
            rescue ArgumentError, TypeError
              false
            end
          when 'String'
            element.is_a? String
          else
            if element.is_a? FHIR::Bundle::Entry
              # Special case for type slicing in a Bundle - look at the resource not the entry
              element = element.resource
            end

            element.is_a? FHIR.const_get(discriminator[:code])
          end
        end

        def find_required_binding_slice(element, discriminator)
          if element.is_a?(FHIR::Coding) && required_binding_value_match?(element, discriminator[:values])
            return element
          end

          coding_path = discriminator[:path].present? ? "#{discriminator[:path]}.coding" : 'coding'

          find_a_value_at(element, coding_path) do |coding|
            required_binding_value_match?(coding, discriminator[:values])
          end
        end

        def find_slice_by_values(element, value_definitions)
          Array.wrap(element).find { |el| verify_slice_by_values(el, value_definitions) }
        end

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
      end
    end
  end
end
