require_relative '../../utils/shared_functions'
require_relative 'care_plan_definitions'
require_relative '../../utils/data_absent_reason_checker'

module USCore
  class CarePlanSearchPatientCategoryStatusTest < Inferno::Test
    include USCore::HelperFunctions
    include USCore::ProfileDefinitions
    include USCore::DataAbsentReasonChecker
    
    input :standalone_patient_id
    title 'Server returns valid results for CarePlan search by patient+category+status.'
    description %(

      A server SHOULD support searching by patient+category+status on the CarePlan resource.
      This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.

    )
    
    id :care_plan_search_patient_category_status_test


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
      care_plan_resources = scratch[:care_plan_resources]
      skip_if care_plan_resources.nil?, 'No Care Plan resources found'

      resolved_one = false
      patient_ids = standalone_patient_id.split(',')
      patient_ids.each do |patient_id|
        next unless care_plan_resources[patient_id].present?

        Array.wrap(care_plan_resources[patient_id]).each do |care_plan|
            search_params = {
              'patient': patient_id,
              'category': get_value_for_search_param(resolve_element_from_path(care_plan, 'category') { |el| get_value_for_search_param(el).present? }),
              'status': get_value_for_search_param(resolve_element_from_path(care_plan, 'status') { |el| get_value_for_search_param(el).present? })
            }
    
            next if search_params.any? { |_param, value| value.nil? }
            resolved_one = true
    
            fhir_search :CarePlan, params: search_params
            
            assert_response_ok
    
            resources_returned = fetch_all_bundled_resources(resource, fhir_client, reply_handler: check_for_data_absent_reasons)
            resources_returned.select! { |resource| resource.resourceType == 'CarePlan' }
    
            resources_returned.each do |resource|
              search_params.each do |key, value|
                unescaped_value = value&.gsub('\\,', ',')
                validate_resource_item(resource, key.to_s, unescaped_value)
              end
            end
    
            value_with_system = get_value_for_search_param(resolve_element_from_path(care_plan, 'category') { |el| get_value_for_search_param(el).present? }, true)
            token_with_system_search_params = search_params.merge('category': value_with_system)
            fhir_search :CarePlan, params: search_params
    
            assert_response_ok

            resources_returned.each do |resource|
              search_params.each do |key, value|
                unescaped_value = value&.gsub('\\,', ',')
                validate_resource_item(resource, key.to_s, unescaped_value)
              end
            end

            break if resolved_one
          end
        end
      skip 'Could not resolve all parameters (patient, category, status) in any resource.' unless resolved_one
    end
  end
end
