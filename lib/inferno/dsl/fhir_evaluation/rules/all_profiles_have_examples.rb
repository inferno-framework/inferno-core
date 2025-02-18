module Inferno
  module DSL
    module FHIREvaluation
      module Rules
        class AllProfilesHaveExamples < Rule
          include ProfileConformanceHelper

          attr_accessor :context, :unused_profile_urls

          def check(context)
            @context = context
            @unused_profile_urls = []
            options = context.config.data['Rule']['AllProfilesHaveExamples']['ConformanceOptions'].to_options

            context.ig.profiles.each do |profile|
              profile_used = context.data.any? { |resource| conforms_to_profile?(resource, profile, options, context.validator) }
              unused_profile_urls << profile.url unless profile_used
            end
            
            unused_profile_urls.uniq!

            if unused_profile_urls.any?
              message = "Found profiles without examples: \n\t #{unused_profile_urls.join(', ')}"
              result = EvaluationResult.new(message, rule: self)
            else
              message = 'All profiles have example instances.'
              result = EvaluationResult.new(message, severity: 'success', rule: self)
            end

            context.add_result result
          end

          def get_profiles_from_example(resource)
            if resource.resourceType == 'Bundle'
              all_profiles = resource.entry.map do |entry|
                get_single_resource_profiles(entry.resource)
              end
              all_profiles << get_profiles_from_example(resource)
              all_profiles.flatten.uniq
            else
              get_single_resource_profiles(resource)
            end
          end

          def get_single_resource_profiles(resource)
            resource&.meta&.profile || []
          end

          def get_unused_profile_urls(profiles, &profile_filter)
            profiles.each do |profile|
              unused_profile_urls.push profile.url unless profile_filter.call(profile)
            end
          end
        end
      end
    end
  end
end
