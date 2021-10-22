require_relative '../../utils/shared_functions'
require_relative 'allergy_intolerance_definitions'

module USCore
  class AllergyIntoleranceVReadTest < Inferno::Test
    include USCore::HelperFunctions
    include USCore::ProfileDefinitions
    
    input :standalone_patient_id
    title 'Server returns correct AllergyIntolerance resource from AllergyIntolerance vread interaction'
    description 'A server SHALL support the AllergyIntolerance vread interaction.'
    
    id :allergy_intolerance_vread_test

    run do
      # skip_if_known_not_supported(:AllergyIntolerance, [:read])
      allergy_intolerance_resources = scratch[:allergy_intolerance_resources]
      skip 'No Allergy Intolerance resources appeart to be available. Please use patients with more information' unless allergy_intolerance_resources.any?

      validate_vread_reply(allergy_intolerance_resources.first) #check for data absent reason
    end
  end
end
