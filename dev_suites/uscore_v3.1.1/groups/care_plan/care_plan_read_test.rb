require_relative '../../utils/shared_functions'

module USCore
  class CarePlanReadTest < Inferno::Test
    include USCore::HelperFunctions
    
    title 'Server returns correct CarePlan resource from CarePlan read interaction'
    description 'A server SHALL support the CarePlan read interaction.'
    
    id :care_plan_read_test

    run do
      # skip_if_known_not_supported(:AllergyIntolerance, [:read])
      resources = scratch[:care_plan_resources]&.values&.flatten
      skip 'No Care Plan resources appeart to be available. Please use patients with more information' unless resources&.any?
      validate_read_reply(resources.first) #check for data absent reason
    end
  end
end
