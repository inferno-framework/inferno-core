require_relative '../../utils/shared_functions'
require_relative 'allergy_intolerance_definitions'

module USCore
  class AllergyIntoleranceMustSupportTest < Inferno::Test
    include USCore::HelperFunctions
    include USCore::ProfileDefinitions
    
    input :standalone_patient_id
    title 'All must support elements are provided in the AllergyIntolerance resources returned.'
    description %(
      US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
      This will look through the AllergyIntolerance resources found previously for the following must support elements:

      * clinicalStatus
      * code
      * patient
      * reaction
      * reaction.manifestation
      * verificationStatus
    )
    
    id :allergy_intolerance_must_support_test

    run do
      allergy_intolerance_resources = scratch[:allergy_intolerance_resources]
      skip 'No Allergy Intolerance resources appeart to be available. Please use patients with more information' unless allergy_intolerance_resources.any?
      must_supports = AllergyintoleranceSequenceDefinitions::MUST_SUPPORTS

      missing_must_support_elements = must_supports[:elements].reject do |element|
        allergy_intolerance_resources.any? do |resource|
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

      skip_if missing_must_support_elements.present?,
              "Could not find #{missing_must_support_elements.join(', ')} in the #{allergy_intolerance_resources.length} provided AllergyIntolerance resource(s)"
    end
  end
end
