require_relative '../../utils/shared_functions'
require_relative 'allergy_intolerance_definitions'
require_relative '../../utils/data_absent_reason_checker'

module USCore
  class AllergyIntoleranceValidateTest < Inferno::Test
    include USCore::HelperFunctions
    include USCore::ProfileDefinitions
    
    input :standalone_patient_id
    title 'AllergyIntolerance resources returned during previous tests conform to the US  Core AllergyIntolerance Profile.'
    description %(

      This test verifies resources returned from the first search conform to the [US  Core AllergyIntolerance Profile](http://hl7.org/fhir/us/core/STU3.1.1/StructureDefinition/us-core-allergyintolerance).
      It verifies the presence of manditory elements and that elements with required bindgings contain appropriate values.
      CodeableConcept element bindings will fail if none of its codings have a code/system that is part of the bound ValueSet.
      Quantity, Coding, and code element bindings will fail if its code/system is not found in the valueset.

      This test also checks that the following CodeableConcepts with
      required ValueSet bindings include a code rather than just text:
      'clinicalStatus' and 'verificationStatus'

    )
    
    id :allergy_intolerance_validate_test

    run do
      # skip_if_known_revinclude_not_supported('AllergyIntolerance', 'Provenance:target')
      allergy_intolerance_resources = scratch[:allergy_intolerance_resources]
      skip 'No Allergy Intolerance resources appeart to be available. Please use patients with more information' unless allergy_intolerance_resources.any?

      profile = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-allergyintolerance'
      test_resources_against_profile(allergy_intolerance_resources, profile) do |resource|
        ['clinicalStatus', 'verificationStatus'].flat_map do |path|
          concepts = resolve_path(resource, path)
          next if concepts.blank?

          code_present = concepts.any? { |concept| concept.coding.any? { |coding| coding.code.present? } }

          unless code_present # rubocop:disable Style/IfUnlessModifier
            "The CodeableConcept at '#{path}' is bound to a required ValueSet but does not contain any codes."
          end
        end.compact
      end

      # bindings = AllergyintoleranceSequenceDefinitions::BINDINGS
      # invalid_binding_messages = []
      # invalid_binding_resources = Set.new
      # bindings.select { |binding_def| binding_def[:strength] == 'required' }.each do |binding_def|
      #   begin
      #     invalid_bindings = resources_with_invalid_binding(binding_def, @allergy_intolerance_ary&.values&.flatten)
      #   rescue Inferno::Terminology::UnknownValueSetException => e
      #     warning do
      #       assert false, e.message
      #     end
      #     invalid_bindings = []
      #   end
      #   invalid_bindings.each { |invalid| invalid_binding_resources << "#{invalid[:resource]&.resourceType}/#{invalid[:resource].id}" }
      #   invalid_binding_messages.concat(invalid_bindings.map { |invalid| invalid_binding_message(invalid, binding_def) })
      # end
      # assert invalid_binding_messages.blank?, "#{invalid_binding_messages.count} invalid required #{'binding'.pluralize(invalid_binding_messages.count)}" \
      # " found in #{invalid_binding_resources.count} #{'resource'.pluralize(invalid_binding_resources.count)}: " \
      # "#{invalid_binding_messages.join('. ')}"

      # bindings.select { |binding_def| binding_def[:strength] == 'extensible' }.each do |binding_def|
      #   begin
      #     invalid_bindings = resources_with_invalid_binding(binding_def, @allergy_intolerance_ary&.values&.flatten)
      #     binding_def_new = binding_def
      #     # If the valueset binding wasn't valid, check if the codes are in the stated codesystem
      #     if invalid_bindings.present?
      #       invalid_bindings = resources_with_invalid_binding(binding_def.except(:system), @allergy_intolerance_ary&.values&.flatten)
      #       binding_def_new = binding_def.except(:system)
      #     end
      #   rescue Inferno::Terminology::UnknownValueSetException, Inferno::Terminology::ValueSet::UnknownCodeSystemException => e
      #     warning do
      #       assert false, e.message
      #     end
      #     invalid_bindings = []
      #   end
      #   invalid_binding_messages.concat(invalid_bindings.map { |invalid| invalid_binding_message(invalid, binding_def_new) })
      # end
      # warning do
      #   invalid_binding_messages.each do |error_message|
      #     assert false, error_message
      #   end
      # end
    end
  end
end
