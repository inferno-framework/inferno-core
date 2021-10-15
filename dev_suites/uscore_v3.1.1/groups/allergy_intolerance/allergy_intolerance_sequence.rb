require_relative '../../utils/shared_functions'
Dir[File.join(__dir__, '*.rb')].each { |file| require file }

module USCore
  class AllergyIntoleranceSequence < Inferno::TestGroup
    include USCore::HelperFunctions
    include USCore::ProfileDefinitions
    title 'AllergyIntolerance Tests'

    description %(
      # Background

      The US Core #{title} sequence verifies that the system under test is able to provide correct responses
      for AllergyIntolerance queries.  These queries must contain resources conforming to US  Core AllergyIntolerance Profile as specified
      in the US Core v3.1.1 Implementation Guide.

      # Testing Methodology


      ## Searching
      This test sequence will first perform each required search associated with this resource. This sequence will perform searches
      with the following parameters:

        * patient



      ### Search Parameters
      The first search uses the selected patient(s) from the prior launch sequence. Any subsequent searches will look for its
      parameter values from the results of the first search. For example, the `identifier` search in the patient sequence is
      performed by looking for an existing `Patient.identifier` from any of the resources returned in the `_id` search. If a
      value cannot be found this way, the search is skipped.

      ### Search Validation
      Inferno will retrieve up to the first 20 bundle pages of the reply for AllergyIntolerance resources and save them
      for subsequent tests.
      Each of these resources is then checked to see if it matches the searched parameters in accordance
      with [FHIR search guidelines](https://www.hl7.org/fhir/search.html). The test will fail, for example, if a patient search
      for gender=male returns a female patient.

      ## Must Support
      Each profile has a list of elements marked as "must support". This test sequence expects to see each of these elements
      at least once. If at least one cannot be found, the test will fail. The test will look through the AllergyIntolerance
      resources found for these elements.

      ## Profile Validation
      Each resource returned from the first search is expected to conform to the [US  Core AllergyIntolerance Profile](http://hl7.org/fhir/us/core/STU3.1.1/StructureDefinition/us-core-allergyintolerance).
      Each element is checked against teminology binding and cardinality requirements.

      Elements with a required binding is validated against its bound valueset. If the code/system in the element is not part
      of the valueset, then the test will fail.

      ## Reference Validation
      Each reference within the resources found from the first search must resolve. The test will attempt to read each reference found
      and will fail if any attempted read fails.
    )

    input :standalone_patient_id

    group 'Server returns valid results for AllergyIntolerance search by patient.' do
      description %(

        A server SHALL support searching by patient on the AllergyIntolerance resource.
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

      
      test from: :allergy_intolerance_search_patient_test
      test from: :allergy_intolerance_search_params_validation
      test from: :allergy_intolerance_search_post
      test from: :allergy_intolerance_search_reference
    end

    group 'Server returns valid results for AllergyIntolerance search by patient+clinical-status.' do
      test from: :allergy_intolerance_search_patient_clinical_status_test
      test from: :allergy_intolerance_search_params_validation
    end

    test from: :allergy_intolerance_read_test
    test from: :allergy_intolerance_vread_test
    test from: :allergy_intolerance_history_test
    test from: :allergy_intolerance_rev_include_test
    test from: :allergy_intolerance_validate_test
    test from: :allergy_intolerance_must_support_test
  end
end
