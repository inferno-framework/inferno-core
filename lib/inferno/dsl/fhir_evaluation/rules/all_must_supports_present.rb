require_relative '../../fhir_resource_navigation'
require_relative '../../must_support_metadata_extractor'
require_relative '../profile_conformance_helper'
require_relative '../../must_support_assessment'

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
          include MustSupportAssessment

          attr_accessor :metadata, :ig

          # check is invoked from the evaluator CLI and applies the logic for this Rule to the provided data.
          # At least one instance of every MustSupport element defined in the profiles must be populated in the data.
          # Findings from the rule will be added to context.results.
          # The logic is configurable with a few options, but this method does not support customizing the metadata.
          # @param context [Inferno::DSL::FHIREvaluation::EvaluationContext]
          # @return [void]
          def check(context)
            missing_items_by_profile = {}
            ig = context.ig
            ig.profiles.each do |profile|
              resources = pick_resources_for_profile(profile, context)
              if resources.blank?
                missing_items_by_profile[profile.url] = ['No matching resources were found to check']
                next
              end
              requirement_extension = context.config.data['Rule']['AllMustSupportsPresent']['RequirementExtensionUrl']
              debug_metadata = context.config.data['Rule']['AllMustSupportsPresent']['WriteMetadataForDebugging']
              missing_items = perform_must_support_test(profile, resources, ig, debug_metadata:, requirement_extension:)
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

          # @private
          def find_ig_and_profile(profile_url, _validator_name)
            # Normally this would be done by a Test's validator,
            # but here we're outside the context of a Test.
            [ig, ig.profile_by_url(profile_url)]
          end
        end
      end
    end
  end
end
