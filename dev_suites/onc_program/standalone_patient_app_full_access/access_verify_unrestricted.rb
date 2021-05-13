module ONCProgram
  class AccessVerifyUnrestricted < Inferno::TestGroup
    title 'Unrestricted Resource Type Access'
    description <<~DESCRIPTION
      This test ensures that apps have full access to USCDI resources if granted access by the tester.
      The tester must grant access to the following resources during the SMART Launch process,
      and this test ensures they all can be accessed:

        * AllergyIntolerance
        * CarePlan
        * CareTeam
        * Condition
        * Device
        * DiagnosticReport
        * DocumentReference
        * Goal
        * Immunization
        * MedicationRequest
        * Observation
        * Procedure
        * Patient
        * Provenance
        * Encounter
        * Practitioner
        * Organization

      For each of the resource types that can be mapped to USCDI data class or elements, this set of tests
      performs a minimum number of requests to determine that the resource type can be accessed given the
      scope granted.  In the case of the Patient resource, this test simply performs a read request.
      For other resources, it performs a search by patient that must be supported by the server.  In some cases,
      servers can return an error message if a status search parameter is not provided.  For these, the
      test will perform an additional search with the required status search parameter.

      This set of tests does not attempt to access resources that do not directly map to USCDI v1, including Encounter, Location,
      Organization, and Practitioner.  It also does not test Provenance, as this
      resource type is accessed by queries through other resource types. These resources types are accessed in the more
      comprehensive Single Patient Query tests.

      However, the authorization system must indicate that access is granted to the Encounter, Practitioner and Organization
      resource types by providing them in the returned scopes because they are required to support the read interaction.
    DESCRIPTION

    id :access_verify_unrestricted

    input :onc_sl_url, :token, :patient_id, :received_scopes

    test do
      title 'Scope granted enables access to all US Core resource types.'
      description <<~DESCRIPTION
        This test confirms that the scopes granted during authorization are sufficient to access
        all relevant US Core resources.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient'

      run {}
    end

    test do
      title 'Access to Patient resource granted and patient resource can be read.'
      description <<~DESCRIPTION
        This test ensures that the authorization service has granted access to the Patient resource
        and that the patient resource can be read without an authorization error.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'

      run {}
    end

    test do
      title 'Access to AllergyIntolerance resource granted and AllergyIntolerance resource can be read.'
      description <<~DESCRIPTION
        This test ensures that the authorization service has granted access to the AllergyIntolerance resource
        and that the AllergyIntolerance resource can be read without an authorization error.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'

      run {}
    end

    test do
      title 'Access to CarePlan resource granted and CarePlan resource can be read.'
      description <<~DESCRIPTION
        This test ensures that the authorization service has granted access to the CarePlan resource
        and that the CarePlan resource can be read without an authorization error.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'

      run {}
    end

    test do
      title 'Access to CareTeam resource granted and CareTeam resource can be read.'
      description <<~DESCRIPTION
        This test ensures that the authorization service has granted access to the CareTeam resource
        and that the CareTeam resource can be read without an authorization error.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'

      run {}
    end

    test do
      title 'Access to Condition resource granted and Condition resource can be read.'
      description <<~DESCRIPTION
        This test ensures that the authorization service has granted access to the Condition resource
        and that the Condition resource can be read without an authorization error.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'

      run {}
    end

    test do
      title 'Access to Device resource granted and Device resource can be read.'
      description <<~DESCRIPTION
        This test ensures that the authorization service has granted access to the Device resource
        and that the Device resource can be read without an authorization error.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'

      run {}
    end

    test do
      title 'Access to DiagnosticReport resource granted and DiagnosticReport resource can be read.'
      description <<~DESCRIPTION
        This test ensures that the authorization service has granted access to the DiagnosticReport resource
        and that the DiagnosticReport resource can be read without an authorization error.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'

      run {}
    end

    test do
      title 'Access to DocumentReference resource granted and DocumentReference resource can be read.'
      description <<~DESCRIPTION
        This test ensures that the authorization service has granted access to the DocumentReference resource
        and that the DocumentReference resource can be read without an authorization error.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'

      run {}
    end

    test do
      title 'Access to Goal resource granted and Goal resource can be read.'
      description <<~DESCRIPTION
        This test ensures that the authorization service has granted access to the Goal resource
        and that the Goal resource can be read without an authorization error.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'

      run {}
    end

    test do
      title 'Access to Immunization resource granted and Immunization resource can be read.'
      description <<~DESCRIPTION
        This test ensures that the authorization service has granted access to the Immunization resource
        and that the Immunization resource can be read without an authorization error.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'

      run {}
    end

    test do
      title 'Access to MedicationRequest resource granted and MedicationRequest resource can be read.'
      description <<~DESCRIPTION
        This test ensures that the authorization service has granted access to the MedicationRequest resource
        and that the MedicationRequest resource can be read without an authorization error.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'

      run {}
    end

    test do
      title 'Access to Observation resource granted and Observation resource can be read.'
      description <<~DESCRIPTION
        This test ensures that the authorization service has granted access to the Observation resource
        and that the Observation resource can be read without an authorization error.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'

      run {}
    end

    test do
      title 'Access to Procedure resource granted and Procedure resource can be read.'
      description <<~DESCRIPTION
        This test ensures that the authorization service has granted access to the Procedure resource
        and that the Procedure resource can be read without an authorization error.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'

      run {}
    end
  end
end
