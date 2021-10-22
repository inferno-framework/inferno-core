require_relative '../../utils/shared_functions'

module USCore
  class CarePlanReferenceResolutionTest < Inferno::Test
    include USCore::HelperFunctions
    
    input :standalone_patient_id
    title 'Every reference within CarePlan resources can be read.'
    description %(
      This test will attempt to read the first 50 reference found in the resources from the first search.
            The test will fail if Inferno fails to read any of those references.
    )
    
    id :care_plan_reference_resolution_test

    run do
      resources = scratch[:care_plan_resources]&.values&.flatten
      skip 'No CarePlan resources appeart to be available. Please use patients with more information' unless resources&.any?

      validated_resources = Set.new
      max_resolutions = 50

      resources.each do |resource|
        validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
      end
    end
  end
end
