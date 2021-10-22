require_relative '../../utils/shared_functions'

module USCore
  class CarePlanVReadTest < Inferno::Test
    include USCore::HelperFunctions
    
    input :standalone_patient_id
    title 'Server returns correct CarePlan resource from CarePlan vread interaction'
    description 'A server SHALL support the CarePlan vread interaction.'
    
    id :care_plan_vread_test

    run do
      # skip_if_known_not_supported(:AllergyIntolerance, [:read])
      resources = scratch[:care_plan_resources]&.values&.flatten
      skip 'No Allergy Intolerance resources appeart to be available. Please use patients with more information' unless resources&.any?

      validate_vread_reply(resources.first) #check for data absent reason
    end
  end
end
