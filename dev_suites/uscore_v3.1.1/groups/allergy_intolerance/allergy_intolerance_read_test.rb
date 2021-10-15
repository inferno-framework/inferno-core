require_relative '../../utils/shared_functions'
require_relative 'allergy_intolerance_definitions'

module USCore
  class AllergyIntoleranceReadTest < Inferno::Test
    include USCore::HelperFunctions
    include USCore::ProfileDefinitions
    
    input :standalone_patient_id
    title 'Server returns correct AllergyIntolerance resource from AllergyIntolerance read interaction'
    description 'A server SHALL support the AllergyIntolerance read interaction.'
    
    id :allergy_intolerance_read_test

    run do
      # skip_if_known_not_supported(:AllergyIntolerance, [:read])
      allergy_intolerance_resources = scratch[:allergy_intolerance_resources]
      skip 'No Allergy Intolerance resources appeart to be available. Please use patients with more information' unless allergy_intolerance_resources.any?

      validate_read_reply(allergy_intolerance_resources.first, :single_patient_client) #check for data absent reason
    end
  end
end
