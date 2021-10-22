require_relative '../../utils/shared_functions'
require_relative 'care_plan_definitions'

module USCore
  class CarePlanMustSupportTest < Inferno::Test
    include USCore::HelperFunctions
    include USCore::ProfileDefinitions
    
    input :standalone_patient_id
    title 'All must support elements are provided in the CarePlan resources returned.'
    description %(
      US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
      This will look through the CarePlan resources found previously for the following must support elements:

      * CarePlan.category:AssessPlan
      * category
      * intent
      * status
      * subject
      * text
      * text.status
    )
    
    id :care_plan_must_support_test

    run do
      resources = scratch[:care_plan_resources]&.values&.flatten
      skip 'No Allergy Intolerance resources appeart to be available. Please use patients with more information' unless resources&.any?
      must_supports = CarePlanSequenceDefinitions::MUST_SUPPORTS

      missing_slices = must_supports[:slices].reject do |slice|
        resources.any? do |resource|
          slice_found = find_slice(resource, slice[:path], slice[:discriminator])
          slice_found.present?
        end
      end

      missing_must_support_elements = must_supports[:elements].reject do |element|
        resources.any? do |resource|
          value_found = resolve_element_from_path(resource, element[:path]) do |value|
            value_without_extensions = value.respond_to?(:to_hash) ? value.to_hash.reject { |key, _| key == 'extension' } : value
            (value_without_extensions.present? || value_without_extensions == false) && (element[:fixed_value].blank? || value == element[:fixed_value])
          end

          # Note that false.present? => false, which is why we need to add this extra check
          value_found.present? || value_found == false
        end
      end

      missing_must_support_elements.each do |must_support|
        warning "#{must_support[:path]}#{': ' + must_support[:fixed_value] if must_support[:fixed_value].present?}"
      end

      missing_must_support_elements += missing_slices.map { |slice| slice[:name] }

      skip_if missing_must_support_elements.present?,
              "Could not find #{missing_must_support_elements.join(', ')} in the #{resources.length} provided CarePlan resource(s)"
    end
  end
end
