require_relative '../../utils/shared_functions'
require_relative 'allergy_intolerance_definitions'

module USCore
  class AllergyIntoleranceSearchPatientClinicalStatusTest < Inferno::Test
    include USCore::HelperFunctions
    include USCore::ProfileDefinitions
    
    input :standalone_patient_id
    title 'Server returns resources when search by patient + clinical-status'
    description 'Server returns resources when search by patient + clinical-status'
    
    id :allergy_intolerance_search_patient_clinical_status_test

    run do
      allergy_intolerance_resources = scratch[:allergy_intolerance_resources]
      search_params = {
        'patient': standalone_patient_id,
        'clinical-status': get_value_for_search_param(resolve_element_from_path(allergy_intolerance_resources, 'clinicalStatus') { |el| get_value_for_search_param(el).present? })
      }

      # next if search_params.any? { |_param, value| value.nil? }
      resolved_one = search_params.none? { |_param, value| value.nil? }
      skip 'Could not resolve all parameters (patient, clinical-status) in any resource.' unless resolved_one
      fhir_search :AllergyIntolerance,
                  params: search_params
      
                  
      assert_response_status(200)
      # assert_valid_bundle_entries(resource_types: ['AllergyIntolerance', 'OperationOutcome'])

      any_resources = resource.entry.any? { |entry| entry.resource.resourceType == 'AllergyIntolerance' }
 
      resources_returned = fetch_all_bundled_resources(resource, fhir_client)
      resources_returned.select! { |resource| resource.resourceType == 'AllergyIntolerance' }
      
      # next unless any_resources
      scratch[:resources_returned] = resources_returned
      scratch[:search_parameters_used] = search_params

    end
  end
end
