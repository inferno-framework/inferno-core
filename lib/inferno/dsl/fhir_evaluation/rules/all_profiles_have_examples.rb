module Inferno
  module DSL
    module FHIREvaluation
      module Rules
        class AllProfilesHaveExamples < Rule
          include ProfileConformanceHelper

          attr_accessor :context, :unused_profile_urls, :all_resources

          def check(context)
            @context = context
            @unused_profile_urls = []
            @all_resources = []
            options = context.config.data['Rule']['AllProfilesHaveExamples']['ConformanceOptions'].to_options

            context.data.map { |entry| extract_resources(entry) }
            all_resources.uniq!

            context.ig.profiles.each do |profile|
              profile_used = all_resources.any? do |resource|
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

          def extract_resources(resource)
            all_resources << resource
            return unless resource.resourceType == 'Bundle'

            resource.entry.map { |entry| extract_resources(entry.resource) }.flatten
          end
        end
      end
    end
  end
end
