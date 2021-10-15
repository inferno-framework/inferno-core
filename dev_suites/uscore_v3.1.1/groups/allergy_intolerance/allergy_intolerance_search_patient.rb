require_relative '../../utils/shared_functions'
require_relative 'allergy_intolerance_definitions'

module USCore
  class AllergyIntoleranceSearchPatientTest < Inferno::Test
    include USCore::HelperFunctions
    include USCore::ProfileDefinitions
    
    input :standalone_patient_id
    title 'Server returns resources when search by patient'
    description 'Server returns resources when search by patient'
    
    id :allergy_intolerance_search_patient_test

    run do
      search_params = {
        patient: standalone_patient_id
      }
      fhir_search :AllergyIntolerance,
                  client: :single_patient_client,
                  params: search_params
      
      # reply = perform_search_with_status(reply, search_params, search_method: :get) if reply.code == 400

      assert_response_ok
      # assert_valid_bundle_entries(resource_types: ['AllergyIntolerance', 'OperationOutcome'])

      any_resources = resource.entry.any? { |entry| entry.resource.resourceType == 'AllergyIntolerance' }
 
      resources_returned = fetch_all_bundled_resources(resource, fhir_client(:single_patient_client))
      resources_returned.select! { |resource| resource.resourceType == 'AllergyIntolerance' }
      
      # next unless any_resources
      scratch[:allergy_intolerance_resources] = resources_returned
      scratch[:resources_returned] = resources_returned
      scratch[:search_parameters_used] = search_params

      save_delayed_sequence_references(resources_returned,
        AllergyintoleranceSequenceDefinitions::DELAYED_REFERENCES, scratch)

    end
  end
end
