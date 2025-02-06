# frozen_string_literal: true

require_relative '../reference_extractor'

module Inferno
  module DSL
    module FHIREvaluation
      module Rules
        class AllProfilesHaveExamples < HasExamples
          attr_accessor :config

          def check(context)
            # TODO: rewrite this to use data.summary
            @used_resources = []
            @config = context.config

            if config.Rule.AllProfilesHaveExamples.TargetExample.byMetaProfile
              @used_resources = context.data.map { |e| profiles(e) }.flatten.uniq
              profile_is_used = proc do |profile|
                versioned_url = "#{profile.url}|#{profile.version}"
                used_resources.include?(profile.url) || used_resources.include?(versioned_url)
              end
              get_unused_resource_urls(context.ig.profiles, &profile_is_used)
            elsif config.Rule.AllProfilesHaveExamples.TargetExample.byConformance
              context.ig.profiles.each do |structure_definition|
                next if structure_definition.abstract

                pass_flg = validate(context)
                unused_resource_urls << structure_definition.url unless pass_flg
              end
            end

            if unused_resource_urls.any?
              message = "Found unused profiles: #{unused_resource_urls.join(', ')}"
              result = EvaluationResult.new(message, rule: self)
            else
              message = 'All profiles have instances'
              result = EvaluationResult.new(message, severity: 'success', rule: self)
            end

            context.add_result result
          end

          def validate(context)
            pass_flg = false
            context.data.each do |resource|
              if structure_definition.type == resource.resourceType
                if config.Environment.ExternalValidator.Enabled
                  pass_flg != Util.validate_resource(resource)
                elsif structure_definition.validates_resource?(resource)
                  pass_flg = true
                end
              end
            end
            pass_flg
          end

          def profiles(resource)
            if resource.resourceType == 'Bundle'
              all_profiles = resource.entry.map do |e|
                single_resource_profiles(e.resource)
              end
              all_profiles << single_resource_profiles(resource)
              all_profiles.flatten.uniq
            else
              single_resource_profiles(resource)
            end
          end

          def single_resource_profiles(resource)
            resource&.meta&.profile || []
          end
        end
      end
    end
  end
end
