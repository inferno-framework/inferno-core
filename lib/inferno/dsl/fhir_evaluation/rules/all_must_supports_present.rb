require_relative '../../fhir_resource_navigation'
require_relative '../../must_support_metadata_extractor'
require_relative '../profile_conformance_helper'

module Inferno
  module DSL
    module FHIREvaluation
      module Rules
        # AllMustSupportsPresent checks that at least one instance of every MustSupport element
        #  defined in the given profiles is populated in the given data.
        # MustSupport elements include plain elements, extensions, and slices.
        # The basis of the test is metadata generated in a first pass that processes the profile into a list of fields,
        #  then the second pass check that all elements in the list are present.
        # This metadata approach allows for customizing what is checked, for example elements may be added or removed,
        #  or choices may be defined where only one choice of multiple must be populated to demonstrate support.
        class AllMustSupportsPresent < Rule
          include FHIRResourceNavigation
          include ProfileConformanceHelper
          attr_accessor :metadata

          # check is invoked from the evaluator CLI and applies the logic for this Rule to the provided data.
          # At least one instance of every MustSupport element defined in the profiles must be populated in the data.
          # Findings from the rule will be added to context.results.
          # The logic is configurable with a few options, but this method does not support customizing the metadata.
          # @param context [Inferno::DSL::FHIREvaluation::EvaluationContext]
          # @return [void]
          def check(context)
            missing_items_by_profile = {}
            context.ig.profiles.each do |profile|
              resources = pick_resources_for_profile(profile, context)
              if resources.blank?
                missing_items_by_profile[profile.url] = ['No matching resources were found to check']
                next
              end
              requirement_extension = context.config.data['Rule']['AllMustSupportsPresent']['RequirementExtensionUrl']
              debug_metadata = context.config.data['Rule']['AllMustSupportsPresent']['WriteMetadataForDebugging']
              profile_metadata = extract_metadata(profile, context.ig, requirement_extension:)
              missing_items = perform_must_support_test_with_metadata(resources, profile_metadata, debug_metadata:)

              missing_items_by_profile[profile.url] = missing_items if missing_items.any?
            end

            if missing_items_by_profile.count.zero?
              result = EvaluationResult.new('All MustSupports are present', severity: 'success', rule: self)
            else
              message = 'Found Profiles with not all MustSupports represented:'
              missing_items_by_profile.each do |profile_url, missing_items|
                message += "\n\t\t#{profile_url}: #{missing_items.join(', ')}"
              end
              result = EvaluationResult.new(message, rule: self)
            end
            context.add_result result
          end

          def pick_resources_for_profile(profile, context)
            conformance_options = context.config.data['Rule']['AllMustSupportsPresent']['ConformanceOptions'].to_options

            # Unless specifically looking for Bundles, break them out into the resources they include
            all_resources =
              if profile.type == 'Bundle'
                context.data
              else
                flatten_bundles(context.data)
              end

            all_resources.filter do |r|
              conforms_to_profile?(r, profile, conformance_options, context.validator)
            end
          end

          # perform_must_support_test is invoked from DSL assertions, allows customizing the metadata with a block.
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
          def perform_must_support_test(profile, resources, ig, debug_metadata: false, requirement_extension: nil)
            profile_metadata = extract_metadata(profile, ig, requirement_extension:)
            yield profile_metadata if block_given?

            perform_must_support_test_with_metadata(resources, profile_metadata, debug_metadata:)
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

            missing_elements(resources)
            missing_slices(resources)
            missing_extensions(resources)

            handle_must_support_choices if metadata.must_supports[:choices].present?

            missing_must_support_strings
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
  end
end
