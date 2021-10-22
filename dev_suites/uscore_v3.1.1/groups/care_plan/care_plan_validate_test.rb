require_relative '../../utils/shared_functions'

module USCore
  class CarePlanValidateTest < Inferno::Test
    include USCore::HelperFunctions
    
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
    
    id :care_plan_validate_test

    run do
      # skip_if_known_revinclude_not_supported('AllergyIntolerance', 'Provenance:target')
      resources = scratch[:care_plan_resources]&.values&.flatten
      skip 'No Allergy Intolerance resources appeart to be available. Please use patients with more information' unless resources&.any?

      profile = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-careplan'
      test_resources_against_profile(resources, profile)
      # bindings stuff
    end
  end
end
