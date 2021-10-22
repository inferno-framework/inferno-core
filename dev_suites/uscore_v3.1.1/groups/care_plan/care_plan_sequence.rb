require_relative '../../utils/shared_functions'
Dir[File.join(__dir__, '*.rb')].each { |file| require file }

module USCore
  class CarePlanSequence < Inferno::TestGroup
    include USCore::HelperFunctions
    include USCore::ProfileDefinitions
    title 'Care Plan Tests'

    description %(
      # Background

      The US Core #{title} sequence verifies that the system under test is able to provide correct responses
      for CarePlan queries.  These queries must contain resources conforming to US Core CarePlan Profile as specified
      in the US Core v3.1.1 Implementation Guide.

      # Testing Methodology


      ## Searching
      This test sequence will first perform each required search associated with this resource. This sequence will perform searches
      with the following parameters:

        * patient + category



      ### Search Parameters
      The first search uses the selected patient(s) from the prior launch sequence. Any subsequent searches will look for its
      parameter values from the results of the first search. For example, the `identifier` search in the patient sequence is
      performed by looking for an existing `Patient.identifier` from any of the resources returned in the `_id` search. If a
      value cannot be found this way, the search is skipped.

      ### Search Validation
      Inferno will retrieve up to the first 20 bundle pages of the reply for CarePlan resources and save them
      for subsequent tests.
      Each of these resources is then checked to see if it matches the searched parameters in accordance
      with [FHIR search guidelines](https://www.hl7.org/fhir/search.html). The test will fail, for example, if a patient search
      for gender=male returns a female patient.

      ## Must Support
      Each profile has a list of elements marked as "must support". This test sequence expects to see each of these elements
      at least once. If at least one cannot be found, the test will fail. The test will look through the CarePlan
      resources found for these elements.

      ## Profile Validation
      Each resource returned from the first search is expected to conform to the [US Core CarePlan Profile](http://hl7.org/fhir/us/core/STU3.1.1/StructureDefinition/us-core-careplan).
      Each element is checked against teminology binding and cardinality requirements.

      Elements with a required binding is validated against its bound valueset. If the code/system in the element is not part
      of the valueset, then the test will fail.

      ## Reference Validation
      Each reference within the resources found from the first search must resolve. The test will attempt to read each reference found
      and will fail if any attempted read fails.
    )

    input :standalone_patient_id

    test from: :care_plan_search_patient_category_test
    test from: :care_plan_search_patient_category_status_test
    test from: :care_plan_read_test
    test from: :care_plan_vread_test
    test from: :care_plan_history_test
    test from: :care_plan_rev_include_test
    test from: :care_plan_validate_test
    test from: :care_plan_must_support_test
    test from: :care_plan_reference_resolution_test
  end
end
