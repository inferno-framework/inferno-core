require_relative '../../utils/shared_functions'
require_relative 'allergy_intolerance_definitions'

module USCore
  class AllergyIntoleranceReferenceResolutionTest < Inferno::Test
    include USCore::HelperFunctions
    include USCore::ProfileDefinitions
    
    input :standalone_patient_id
    title 'Every reference within AllergyIntolerance resources can be read.'
    description %(
      This test will attempt to read the first 50 reference found in the resources from the first search.
      The  test will fail if Inferno fails to read any of those references.
    )
    
    id :allergy_intolerance_reference_resolution_test

    run do
      allergy_intolerance_resources = scratch[:allergy_intolerance_resources]
      skip 'No Allergy Intolerance resources appeart to be available. Please use patients with more information' unless allergy_intolerance_resources&.any?

      validated_resources = Set.new
      max_resolutions = 50

      allergy_intolerance_resources.each do |resource|
        validate_reference_resolutions(resource, validated_resources, max_resolutions) if validated_resources.length < max_resolutions
      end
    end
  end
end
