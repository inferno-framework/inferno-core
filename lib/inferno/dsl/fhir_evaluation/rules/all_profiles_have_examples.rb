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

            used_resources = context.data.map { |entry| extract_resource(entry) }.flatten.uniq
            context.ig.profiles.each do |profile|
              profile_used = used_resources.any? do |resource|
                conforms_to_profile?(resource, profile, options, context.validator)
              end
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

          def extract_resource(resource)
            if resource.resourceType == 'Bundle'
              all_profiles = resource.entry.map(&:resource)
              all_profiles << resource
              all_profiles.flatten.uniq
            else
              resource
            end
          end
        end
      end
    end
  end
end
