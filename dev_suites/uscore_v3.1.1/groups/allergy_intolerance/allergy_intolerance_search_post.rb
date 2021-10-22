require_relative '../../utils/shared_functions'
require_relative 'allergy_intolerance_definitions'

module USCore
  class AllergyIntoleranceSearchPostTest < Inferno::Test
    include USCore::HelperFunctions
    include USCore::ProfileDefinitions
    
    input :standalone_patient_id
    title 'Server returns resources when search by patient post'
    description 'Server returns resources when search by patient post'
    
    id :allergy_intolerance_search_post

    run do
      search_params = {
        patient: standalone_patient_id
      }

      resources_returned = scratch[:allergy_intolerance_resources]
      omit_if resources_returned.nil?, 'No Allergy Intolerance resources found'
      #  this isn't actually searching by post?
      fhir_search :AllergyIntolerance,
        params: search_params,
        search_method: :post
      
      assert_response_status(200)
      # assert_valid_bundle_entries(resource_types: ['AllergyIntolerance', 'OperationOutcome'])
      search_by_post_resources = fetch_all_bundled_resources(resource, fhir_client)
      search_by_post_resources.select! { |resource| resource.resourceType == 'AllergyIntolerance' }
      assert search_by_post_resources.length == resources_returned.length

    end
  end
end
