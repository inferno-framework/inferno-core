require_relative '../../utils/shared_functions'
require_relative 'allergy_intolerance_definitions'

module USCore
  class AllergyIntoleranceSearchReferenceTest < Inferno::Test
    include USCore::HelperFunctions
    include USCore::ProfileDefinitions
    
    input :standalone_patient_id
    title 'Server returns resources when search by patient reference'
    description 'Server returns resources when search by patient reference'
    
    id :allergy_intolerance_search_reference

    run do
      search_params = {
        patient: standalone_patient_id
      }

      search_params = search_params.merge(patient: "Patient/#{standalone_patient_id}")
      fhir_search :AllergyIntolerance,
                  client: :single_patient_client,
                  params: search_params
      assert_response_status(200)
      # assert_valid_bundle_entries(resource_types: ['AllergyIntolerance', 'OperationOutcome'])
    end
  end
end
