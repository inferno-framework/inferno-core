module ONCProgram
  class USCorePractitioner < Inferno::TestGroup
    title 'Practitioner Tests'
    description <<~DESCRIPTION
      # Background

      The US Core #{title} sequence verifies that the system under test is able to provide correct responses
      for Practitioner queries.  These queries must contain resources conforming to US Core Practitioner Profile as specified
      in the US Core v3.1.1 Implementation Guide.

      # Testing Methodology


      ## Searching
      This test sequence will first perform each required search associated with this resource. This sequence will perform searches
      with the following parameters:

        * _id
        * identifier
        * name
        * birthdate + name
        * gender + name



      ### Search Parameters
      The first search uses the selected patient(s) from the prior launch sequence. Any subsequent searches will look for its
      parameter values from the results of the first search. For example, the `identifier` search in the patient sequence is
      performed by looking for an existing `Patient.identifier` from any of the resources returned in the `_id` search. If a
      value cannot be found this way, the search is skipped.

      ### Search Validation
      Inferno will retrieve up to the first 20 bundle pages of the reply for Patient resources and save them
      for subsequent tests.
      Each of these resources is then checked to see if it matches the searched parameters in accordance
      with [FHIR search guidelines](https://www.hl7.org/fhir/search.html). The test will fail, for example, if a patient search
      for gender=male returns a female patient.

      ## Must Support
      Each profile has a list of elements marked as "must support". This test sequence expects to see each of these elements
      at least once. If at least one cannot be found, the test will fail. The test will look through the Patient
      resources found for these elements.

      ## Profile Validation
      Each resource returned from the first search is expected to conform to the [US Core Patient Profile](http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient).
      Each element is checked against teminology binding and cardinality requirements.

      Elements with a required binding is validated against its bound valueset. If the code/system in the element is not part
      of the valueset, then the test will fail.

      ## Reference Validation
      Each reference within the resources found from the first search must resolve. The test will attempt to read each reference found
      and will fail if any attempted read fails.
    DESCRIPTION

    id :us_core_practitioner

    input :url, :token, :patient_ids

    test do
      title 'Server returns valid results for Practitioner search by _id.'
      description <<~DESCRIPTION
        A server SHALL support searching by _id on the Practitioner resource.
        This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.
        Because this is the first search of the sequence, resources in the response will be used for subsequent tests.
      DESCRIPTION
      # link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'

      run {}
    end

    test do
      title 'Server returns valid results for Practitioner search by identifier.'
      description <<~DESCRIPTION
        A server SHALL support searching by identifier on the Practitioner resource.
        This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.
      DESCRIPTION
      # link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'

      run {}
    end

    test do
      title 'Server returns valid results for Practitioner search by name.'
      description <<~DESCRIPTION
        A server SHALL support searching by name on the Practitioner resource.
        This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.
      DESCRIPTION
      # link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'

      run {}
    end

    test do
      title 'Server returns valid results for Practitioner search by birthdate+name.'
      description <<~DESCRIPTION
        A server SHALL support searching by birthdate+name on the Practitioner resource.
        This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.
      DESCRIPTION
      # link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'

      run {}
    end

    test do
      title 'Server returns valid results for Practitioner search by gender+name.'
      description <<~DESCRIPTION
        A server SHALL support searching by gender+name on the Practitioner resource.
        This test will pass if resources are returned and match the search criteria. If none are returned, the test is skipped.
      DESCRIPTION
      # link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'

      run {}
    end

    test do
      title 'Server returns correct Practitioner resource from Practitioner read interaction'
      description <<~DESCRIPTION
        A server SHALL support the Practitioner read interaction.
      DESCRIPTION
      # link 'https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html'

      run {}
    end

    test do
      title 'Practitioner resources returned from previous search conform to the US Core Practitioner Profile.'
      description <<~DESCRIPTION
        This test verifies resources returned from the first search conform to the [US Core Practitioner Profile](http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitioner).
        It verifies the presence of manditory elements and that elements with required bindgings contain appropriate values.
        CodeableConcept element bindings will fail if none of its codings have a code/system that is part of the bound ValueSet.
        Quantity, Coding, and code element bindings will fail if its code/system is not found in the valueset.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitioner'

      run {}
    end

    test do
      title 'All must support elements are provided in the Practitioner resources returned.'
      description <<~DESCRIPTION
        US Core Responders SHALL be capable of populating all data elements as part of the query results as specified by the US Core Server Capability Statement.
        This will look through the Practitioner resources found previously for the following must support elements:

        * Practitioner.extension:birthsex
        * Practitioner.extension:ethnicity
        * Practitioner.extension:race
        * address
        * address.city
        * address.line
        * address.period
        * address.postalCode
        * address.state
        * birthDate
        * communication
        * communication.language
        * gender
        * identifier
        * identifier.system
        * identifier.value
        * name
        * name.family
        * name.given
        * telecom
        * telecom.system
        * telecom.use
        * telecom.value
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/us/core/general-guidance.html#must-support'

      run {}
    end

    test do
      title 'Every reference within Practitioner resources can be read.'
      description <<~DESCRIPTION
        This test will attempt to read the first 50 reference found in the resources from the first search.
        The test will fail if Inferno fails to read any of those references.
      DESCRIPTION
      # link 'http://hl7.org/fhir/references.html'

      run {}
    end
  end
end
