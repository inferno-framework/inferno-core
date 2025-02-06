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

        # Check whether the given resource conforms to the given profile, using the given options
        # to select which approaches are considered.
        # Current options:
        # - If the resource is the right resourceType
        # - If the resource claims conformance in resource.meta.profile
        # - If the resource validates against the profile using the FHIR validator (NOT YET IMPLEMENTED)
        # - If the resource meets other criteria defined in the block.
        #   As an example, the block may look for the presence of certain codes, such as LOINC "8867-4"
        #   in an Observation category code suggests that the resource intended to conform to a "Heart Rate" profile
        # @param resource [FHIR::Resource]
        # @param profile [FHIR::StructureDefinition]
        # @param options [Hash] Hash of boolean-valued options. See DEFAULT_OPTIONS for defaults and keys
        # @param validator [Inferno::DSL::FHIRResourceValidation::Validator]
        # @yieldparam resource [FHIR::Resource] The original resource
        # @yieldreturn [Boolean]
        # @return [Boolean]
        def conforms_to_profile?(resource, profile, options = DEFAULT_OPTIONS, validator = nil) # rubocop:disable Metrics/CyclomaticComplexity
          return false if resource.resourceType != profile.type

          return true if options[:considerOnlyResourceType]

          return true if options[:considerMetaProfile] && declares_meta_profile?(resource, profile)

          return true if options[:considerValidationResults] && validates_profile?(resource, profile, validator)

          return true if block_given? && yield(resource)

          false
        end

        # Check if the given resource claims conformance to the profile, versioned or unversioned,
        # based on resource.meta.profile.
        # @param resource [FHIR::Resource]
        # @param profile [FHIR::StructureDefinition]
        def declares_meta_profile?(resource, profile)
          declared_profiles = resource&.meta&.profile || []
          profile_url = profile.url
          versioned_url = "#{profile_url}|#{profile.version}"

          declared_profiles.include?(profile_url) || declared_profiles.include?(versioned_url)
        end

        # @private until implemented
        def validates_profile?(_resource, _profile, _validator)
          raise 'Profile validation is not yet implemented. ' \
                'Set considerValidationResults=false.'
        end
      end
    end
  end
end
