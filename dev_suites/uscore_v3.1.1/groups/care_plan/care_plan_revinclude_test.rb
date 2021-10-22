require_relative '../../utils/shared_functions'
require_relative 'care_plan_definitions'
require_relative '../../utils/data_absent_reason_checker'

module USCore
  class CarePlanRevIncludeTest < Inferno::Test
    include USCore::HelperFunctions
    include USCore::ProfileDefinitions
    include USCore::DataAbsentReasonChecker
    
    input :standalone_patient_id
    title 'Server returns Provenance resources from CarePlan search by patient + category + _revIncludes: Provenance:target'
    description %(
     
      A Server SHALL be capable of supporting the following _revincludes: Provenance:target.

      This test will perform a search for patient + category + _revIncludes: Provenance:target and will pass
      if a Provenance resource is found in the reponse.
    )
    
    id :care_plan_rev_include_test

    run do
      # skip_if_known_revinclude_not_supported('AllergyIntolerance', 'Provenance:target')
      patient_ids = standalone_patient_id.split(',')
      resources = scratch[:care_plan_resources]
      skip 'No Care Plan resources appeart to be available. Please use patients with more information' unless resources.any?

      provenance_results = []
      resolved_one = false
      patient_ids.each do |patient|
        search_params = {
          'patient': patient,
          'category': get_value_for_search_param(resolve_element_from_path(resources[patient], 'category') { |el| get_value_for_search_param(el).present? }),
          '_revinclude': 'Provenance:target'
        }

        next if search_params.any? { |_param, value| value.nil? }
        resolved_one = true

        fhir_search :CarePlan, params: search_params
        # reply = perform_search_with_status(reply, search_params, search_method: :get) if reply.code == 400 
        assert_response_ok
        # assert_valid_bundle_entries
        provenance_results += fetch_all_bundled_resources(resource, fhir_client, reply_handler: check_for_data_absent_reasons)
          .select { |resource| resource.resourceType == 'Provenance' }

      end

      # save_resource_references(versioned_resource_class('Provenance'), provenance_results)
      save_delayed_sequence_references(provenance_results, AllergyintoleranceSequenceDefinitions::DELAYED_REFERENCES, scratch)
      skip 'Could not resolve all parameters (patient, category) in any resource.' unless resolved_one
      skip 'No Provenance resources were returned from this search' unless provenance_results.present?
    end
  end
end
