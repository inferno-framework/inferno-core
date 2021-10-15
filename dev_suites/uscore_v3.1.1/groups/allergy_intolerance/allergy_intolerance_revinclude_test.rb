require_relative '../../utils/shared_functions'
require_relative 'allergy_intolerance_definitions'
require_relative '../../utils/data_absent_reason_checker'

module USCore
  class AllergyIntoleranceRevIncludeTest < Inferno::Test
    include USCore::HelperFunctions
    include USCore::ProfileDefinitions
    include USCore::DataAbsentReasonChecker
    
    input :standalone_patient_id
    title 'Server returns Provenance resources from AllergyIntolerance search by patient + _revIncludes: Provenance:target'
    description %(

      A Server SHALL be capable of supporting the following _revincludes: Provenance:target.

      This test will perform a search for patient + _revIncludes: Provenance:target and will pass
      if a Provenance resource is found in the reponse.

    )
    
    id :allergy_intolerance_rev_include_test

    run do
      # skip_if_known_revinclude_not_supported('AllergyIntolerance', 'Provenance:target')
      allergy_intolerance_resources = scratch[:allergy_intolerance_resources]
      skip 'No Allergy Intolerance resources appeart to be available. Please use patients with more information' unless allergy_intolerance_resources.any?

      provenance_results = []
      # patient_ids.each do |patient|
      search_params = {
        'patient': standalone_patient_id,
        '_revinclude': 'Provenance:target'
      }

      fhir_search :AllergyIntolerance,
                  client: :single_patient_client,
                  params: search_params

      # reply = perform_search_with_status(reply, search_params, search_method: :get) if reply.code == 400

      assert_response_ok
      # assert_valid_bundle_entries
      provenance_results += fetch_all_bundled_resources(resource, fhir_client(:single_patient_client), reply_handler: check_for_data_absent_reasons)
        .select { |resource| resource.resourceType == 'Provenance' }
      # end

      # save_resource_references(versioned_resource_class('Provenance'), provenance_results)
      save_delayed_sequence_references(provenance_results,
        AllergyintoleranceSequenceDefinitions::DELAYED_REFERENCES, scratch)

      skip 'No Provenance resources were returned from this search' unless provenance_results.present?
    end
  end
end
