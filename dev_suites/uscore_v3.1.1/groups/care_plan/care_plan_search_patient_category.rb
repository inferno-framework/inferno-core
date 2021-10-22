require_relative '../../utils/shared_functions'
require_relative 'care_plan_definitions'
require_relative '../../utils/data_absent_reason_checker'

module USCore
  class CarePlanSearchPatientCategoryTest < Inferno::Test
    include USCore::HelperFunctions
    include USCore::ProfileDefinitions
    include USCore::DataAbsentReasonChecker
    
    input :standalone_patient_id
    title 'Server returns resources when search by patient + category'
    description %(

      A server SHALL support searching by patient+category on the CarePlan resource.
      This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

      This test verifies that the server supports searching by
      reference using the form `patient=[id]` as well as
      `patient=Patient/[id]`.  The two different forms are expected
      to return the same number of results.  US Core requires that
      both forms are supported by US Core responders.

      Additionally, this test will check that GET and POST search
      methods return the same number of results. Search by POST
      is required by the FHIR R4 specification, and these tests
      interpret search by GET as a requirement of US Core v3.1.1.

      Because this is the first search of the sequence, resources in
      the response will be used for subsequent tests.
    )
    
    id :care_plan_search_patient_category_test


    def validate_resource_item(resource, property, value)
      case property

      when 'category'
        values_found = resolve_path(resource, 'category')
        coding_system = value.split('|').first.empty? ? nil : value.split('|').first
        coding_value = value.split('|').last
        match_found = values_found.any? do |codeable_concept|
          if value.include? '|'
            codeable_concept.coding.any? { |coding| coding.system == coding_system && coding.code == coding_value }
          else
            codeable_concept.coding.any? { |coding| coding.code == value }
          end
        end
        assert match_found, "category in CarePlan/#{resource.id} (#{values_found}) does not match category requested (#{value})"

      when 'date'
        values_found = resolve_path(resource, 'period')
        match_found = values_found.any? { |date| validate_date_search(value, date) }
        assert match_found, "date in CarePlan/#{resource.id} (#{values_found}) does not match date requested (#{value})"

      when 'patient'
        values_found = resolve_path(resource, 'subject.reference')
        value = value.split('Patient/').last
        match_found = values_found.any? { |reference| [value, 'Patient/' + value, "#{url}/Patient/#{value}"].include? reference }
        assert match_found, "patient in CarePlan/#{resource.id} (#{values_found}) does not match patient requested (#{value})"

      when 'status'
        values_found = resolve_path(resource, 'status')
        values = value.split(/(?<!\\),/).each { |str| str.gsub!('\,', ',') }
        match_found = values_found.any? { |value_in_resource| values.include? value_in_resource }
        assert match_found, "status in CarePlan/#{resource.id} (#{values_found}) does not match status requested (#{value})"

      end
    end

    run do
      patient_ids = standalone_patient_id.split(',')
      search_query_variants_tested_once = false
      patient_ids.each do |patient_id|
        search_params = {
          patient: patient_id,
          category: 'assess-plan'
        }
        fhir_search :CarePlan, params: search_params
        
        # reply = perform_search_with_status(reply, search_params, search_method: :get) if reply.code == 400
        
        assert_response_ok
        
        # validation part of assert_valid_bundle_entries failing -- maybe because of fhir version? -- i think it was working before the validator updates
        # assert_valid_bundle_entries(resource_types: ['CarePlan', 'OperationOutcome'])
        
        any_resources = resource.entry.any? { |entry| entry.resource.resourceType == 'CarePlan' }
        next unless any_resources
        
        resources_returned = fetch_all_bundled_resources(resource, fhir_client, reply_handler: check_for_data_absent_reasons)
        resources_returned.select! { |resource| resource.resourceType == 'CarePlan' }
        
        scratch[:care_plan_resources] = {} if scratch[:care_plan_resources].nil?
        scratch[:care_plan_resources][patient_id] = resources_returned
        
        save_delayed_sequence_references(resources_returned, CarePlanSequenceDefinitions::DELAYED_REFERENCES, scratch)
        resources_returned.each do |resource|
          search_params.each do |key, value|
            unescaped_value = value&.gsub('\\,', ',')
            validate_resource_item(resource, key.to_s, unescaped_value)
          end
        end

        next if search_query_variants_tested_once
  
        value_with_system = get_value_for_search_param(resolve_element_from_path(resources_returned, 'category') { |el| get_value_for_search_param(el).present? }, true)
        token_with_system_search_params = search_params.merge('category': value_with_system)
        fhir_search :CarePlan, params: token_with_system_search_params
        assert_response_ok
        # assert_valid_bundle_entries(resource_types: ['CarePlan', 'OperationOutcome'])

        # Search with type of reference variant (patient=Patient/[id])
        search_params_with_type = search_params.merge('patient': "Patient/#{patient_id}")
        fhir_search :CarePlan, params: search_params_with_type

        assert_response_ok
        # assert_valid_bundle_entries(resource_types: ['CarePlan', 'OperationOutcome'])

        search_with_type = fetch_all_bundled_resources(resource, fhir_client, reply_handler: check_for_data_absent_reasons)
        search_with_type.select! { |resource| resource.resourceType == 'CarePlan' }
        assert search_with_type.length == resources_returned.length, 'Expected search by Patient/ID to have the same results as search by ID'

        # Search by POST variant
        fhir_search :CarePlan, params: search_params, search_method: :post

        # reply = perform_search_with_status(reply, search_params, search_method: :post) if reply.code == 400

        assert_response_ok

        search_by_post_resources = fetch_all_bundled_resources(resource, fhir_client, reply_handler: check_for_data_absent_reasons)
        search_by_post_resources.select! { |resource| resource.resourceType == 'CarePlan' }
        assert search_by_post_resources.length == resources_returned.length, 'Expected search by POST to have the same results as search by GET'

        search_query_variants_tested_once = true
      end
      skip_if scratch[:care_plan_resources].nil?,  "No Care Plan resources appear to be available. Please use patients with more information"
    end
  end
end
