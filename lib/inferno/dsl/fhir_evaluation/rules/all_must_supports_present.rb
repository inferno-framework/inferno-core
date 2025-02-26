require_relative '../../fhir_resource_navigation'
require_relative '../../must_support_metadata_extractor'
require_relative '../profile_conformance_helper'
require_relative '../../must_support_test'

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
          include MustSupportTest

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
        end
      end
    end
  end
end
