module ONCProgram
  class AccessVerifyRestricted < Inferno::TestGroup
    title 'Restricted Resource Type Access'
    description <<~DESCRIPTION
      This test ensures that patients are able to grant or deny access to a
      subset of resources to an app. It also verifies that patients can
      prevent issuance of a refresh token by denying the `offline_access`
      scope. The tester provides a list of resources that will be granted
      during the SMART App Launch process, and this test verifies that the
      scopes granted are consistent with what the tester provided. It also
      formulates queries to ensure that the app is either given access to,
      or denied access to, the appropriate resource types based on those
      chosen by the tester.

      Resources that can be mapped to USCDI are checked in this test, including:

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

      For each of the resources that can be mapped to USCDI data class or
      elements, this set of tests performs a minimum number of requests to
      determine if access to the resource type is appropriately allowed or
      denied given the scope granted. In the case of the Patient resource,
      this test simply performs a read request. For other resources, it
      performs a search by patient that must be supported by the server. In
      some cases, servers can return an error message if a status search
      parameter is not provided. For these, the test will perform an
      additional search with the required status search parameter.

      This set of tests does not attempt to access resources that do not
      directly map to USCDI v1, including Encounter, Location,
      Organization, and Practitioner. It also does not test Provenance, as
      this resource type is accessed by queries through other resource
      types. These resource types are accessed in the more comprehensive
      Single Patient Query tests.

      If the tester chooses to not grant access to a resource, the queries
      associated with that resource must result in either a 401
      (Unauthorized) or 403 (Forbidden) status code. The flexiblity
      provided here is due to some ambiguity in the specifications tested.
    DESCRIPTION

    id :access_verify_restricted

    input :onc_sl_url, :token, :patient_id, :received_scopes, :onc_sl_expected_resources

    test do
      title 'Scope granted is limited to those chosen by user during authorization.'
      description <<~DESCRIPTION
        This test confirms that the scopes granted during authorization match those that
        were expected for this launch based on input provided by the tester.
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
      title 'Access to AllergyIntolerance resources are restricted properly based on patient-selected scope'
      description <<~DESCRIPTION
        This test ensures that access to the AllergyIntolerance is granted or denied based on the
        selection by the tester prior to the execution of the test.  If the tester indicated that access
        will be granted to this resource, this test verifies that
        a search by patient in this resource does not result in an access denied result.  If the tester indicated that
        access will be denied for this resource, this verifies that
        search by patient in the resource results in an access denied result.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'

      run {}
    end

    test do
      title 'Access to CarePlan resources are restricted properly based on patient-selected scope'
      description <<~DESCRIPTION
        This test ensures that access to the CarePlan is granted or denied based on the
        selection by the tester prior to the execution of the test.  If the tester indicated that access
        will be granted to this resource, this test verifies that
        a search by patient in this resource does not result in an access denied result.  If the tester indicated that
        access will be denied for this resource, this verifies that
        search by patient in the resource results in an access denied result.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'

      run {}
    end

    test do
      title 'Access to CareTeam resources are restricted properly based on patient-selected scope'
      description <<~DESCRIPTION
        This test ensures that access to the CareTeam is granted or denied based on the
        selection by the tester prior to the execution of the test.  If the tester indicated that access
        will be granted to this resource, this test verifies that
        a search by patient in this resource does not result in an access denied result.  If the tester indicated that
        access will be denied for this resource, this verifies that
        search by patient in the resource results in an access denied result.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'

      run {}
    end

    test do
      title 'Access to Condition resources are restricted properly based on patient-selected scope'
      description <<~DESCRIPTION
        This test ensures that access to the Condition is granted or denied based on the
        selection by the tester prior to the execution of the test.  If the tester indicated that access
        will be granted to this resource, this test verifies that
        a search by patient in this resource does not result in an access denied result.  If the tester indicated that
        access will be denied for this resource, this verifies that
        search by patient in the resource results in an access denied result.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'

      run {}
    end

    test do
      title 'Access to Device resources are restricted properly based on patient-selected scope'
      description <<~DESCRIPTION
        This test ensures that access to the Device is granted or denied based on the
        selection by the tester prior to the execution of the test.  If the tester indicated that access
        will be granted to this resource, this test verifies that
        a search by patient in this resource does not result in an access denied result.  If the tester indicated that
        access will be denied for this resource, this verifies that
        search by patient in the resource results in an access denied result.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'

      run {}
    end

    test do
      title 'Access to DiagnosticReport resources are restricted properly based on patient-selected scope'
      description <<~DESCRIPTION
        This test ensures that access to the DiagnosticReport is granted or denied based on the
        selection by the tester prior to the execution of the test.  If the tester indicated that access
        will be granted to this resource, this test verifies that
        a search by patient in this resource does not result in an access denied result.  If the tester indicated that
        access will be denied for this resource, this verifies that
        search by patient in the resource results in an access denied result.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'

      run {}
    end

    test do
      title 'Access to DocumentReference resources are restricted properly based on patient-selected scope'
      description <<~DESCRIPTION
        This test ensures that access to the DocumentReference is granted or denied based on the
        selection by the tester prior to the execution of the test.  If the tester indicated that access
        will be granted to this resource, this test verifies that
        a search by patient in this resource does not result in an access denied result.  If the tester indicated that
        access will be denied for this resource, this verifies that
        search by patient in the resource results in an access denied result.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'

      run {}
    end

    test do
      title 'Access to Goal resources are restricted properly based on patient-selected scope'
      description <<~DESCRIPTION
        This test ensures that access to the Goal is granted or denied based on the
        selection by the tester prior to the execution of the test.  If the tester indicated that access
        will be granted to this resource, this test verifies that
        a search by patient in this resource does not result in an access denied result.  If the tester indicated that
        access will be denied for this resource, this verifies that
        search by patient in the resource results in an access denied result.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'

      run {}
    end

    test do
      title 'Access to Immunization resources are restricted properly based on patient-selected scope'
      description <<~DESCRIPTION
        This test ensures that access to the Immunization is granted or denied based on the
        selection by the tester prior to the execution of the test.  If the tester indicated that access
        will be granted to this resource, this test verifies that
        a search by patient in this resource does not result in an access denied result.  If the tester indicated that
        access will be denied for this resource, this verifies that
        search by patient in the resource results in an access denied result.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'

      run {}
    end

    test do
      title 'Access to MedicationRequest resources are restricted properly based on patient-selected scope'
      description <<~DESCRIPTION
        This test ensures that access to the MedicationRequest is granted or denied based on the
        selection by the tester prior to the execution of the test.  If the tester indicated that access
        will be granted to this resource, this test verifies that
        a search by patient in this resource does not result in an access denied result.  If the tester indicated that
        access will be denied for this resource, this verifies that
        search by patient in the resource results in an access denied result.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'

      run {}
    end

    test do
      title 'Access to Observation resources are restricted properly based on patient-selected scope'
      description <<~DESCRIPTION
        This test ensures that access to the Observation is granted or denied based on the
        selection by the tester prior to the execution of the test.  If the tester indicated that access
        will be granted to this resource, this test verifies that
        a search by patient in this resource does not result in an access denied result.  If the tester indicated that
        access will be denied for this resource, this verifies that
        search by patient in the resource results in an access denied result.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'

      run {}
    end

    test do
      title 'Access to Procedure resources are restricted properly based on patient-selected scope'
      description <<~DESCRIPTION
        This test ensures that access to the Procedure is granted or denied based on the
        selection by the tester prior to the execution of the test.  If the tester indicated that access
        will be granted to this resource, this test verifies that
        a search by patient in this resource does not result in an access denied result.  If the tester indicated that
        access will be denied for this resource, this verifies that
        search by patient in the resource results in an access denied result.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/scopes-and-launch-context/index.html'

      run {}
    end
  end
end
