require_relative '../../utils/shared_functions'

module USCore
  class CarePlanHistoryTest < Inferno::Test
    include USCore::HelperFunctions
    
    title 'Server returns correct CarePlan resource from CarePlan history interaction'
    description 'A server SHALL support the CarePlan history interaction.'
    
    id :care_plan_history_test

    run do
      # skip_if_known_not_supported(:AllergyIntolerance, [:read])
      resources = scratch[:care_plan_resources]&.values&.flatten
      skip 'No Allergy Intolerance resources appeart to be available. Please use patients with more information' unless resources&.any?

      validate_history_reply(resources.first) #check for data absent reason
    end
  end
end
