module Inferno
  module DSL
    module FHIREvaluation
      # This module is used to decide whether a resource instantiates a given profile.
      # Aligning resources to profiles is necessary when evaluating the comprehensiveness
      # of the resources with respect to those profiles, unfortunately it's impossible to
      # programmatically determine intent. (i.e, is this resource supposed to instantiate this profile?)
      # This module offers some approaches to make that determination.
      module ProfileConformanceHelper
        DEFAULT_OPTIONS = {
          considerMetaProfile: true,
          considerValidationResults: false,
          considerOnlyResourceType: false
        }.freeze

        def conforms_to_profile?(resource, profile, options = DEFAULT_OPTIONS, validator = nil)
          return false if resource.resourceType != profile.type

          options[:considerOnlyResourceType] ||
            consider_meta_profile(resource, profile, options) ||
            consider_validation_results(resource, profile, options, validator) ||
            (block_given? && yield(resource))
        end

        def consider_meta_profile(resource, profile, options)
          options[:considerMetaProfile] && declares_meta_profile?(resource, profile)
        end

        def declares_meta_profile?(resource, profile)
          declared_profiles = resource&.meta&.profile || []
          profile_url = profile.url
          versioned_url = "#{profile_url}|#{profile.version}"

          declared_profiles.include?(profile_url) || declared_profiles.include?(versioned_url)
        end

        def consider_validation_results(resource, profile, options, validator)
          options[:considerValidationResults] && validates_profile?(resource, profile, validator)
        end

        def validates_profile?(_resource, _profile, _validator)
          raise 'Profile validation is not yet implemented. ' \
                'Set considerValidationResults=false.'
        end
      end
    end
  end
end
