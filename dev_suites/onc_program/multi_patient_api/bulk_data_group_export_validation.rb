module ONCProgram
  class BulkDataGroupExportValidation < Inferno::TestGroup
    title 'Group Compartment Export Validation Tests'
    description <<~DESCRIPTION
      Verify that Group compartment export from the Bulk Data server follow US Core Implementation Guide
    DESCRIPTION

    id :bulk_data_group_export_validation

    input :bulk_status_output, :bulk_lines_to_validate, :bulk_patient_ids_in_group, :bulk_device_types_in_group

    test do
      title 'Bulk Data Server is secured by transport layer security'
      description <<~DESCRIPTION
        [§170.315(g)(10) Test Procedure](https://www.healthit.gov/test-method/standardized-api-patient-and-population-services) requires that
        all exchanges described herein between a client and a server SHALL be secured using Transport Layer Security (TLS) Protocol Version 1.2 (RFC5246).
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/export/index.html#security-considerations'

      run {}
    end

    test do
      title 'NDJSON download requires access token if requireAccessToken is true'
      description <<~DESCRIPTION
        If the requiresAccessToken field in the Complete Status body is set to true, the request SHALL include a valid access token.

        [FHIR R4 Security](http://build.fhir.org/security.html#AccessDenied) and
        [The OAuth 2.0 Authorization Framework: Bearer Token Usage](https://tools.ietf.org/html/rfc6750#section-3.1)
        recommend using HTTP status code 401 for invalid token but also allow the actual result be controlled by policy and context.
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/export/index.html#file-request'

      run {}
    end

    test do
      title 'Patient resources returned conform to the US Core Patient Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient'

      run {}
    end

    test do
      title 'Group export has at least two patients'
      description <<~DESCRIPTION
        This test verifies that the Group export has at least two patients.
      DESCRIPTION
      # link 'http://ndjson.org/'

      run {}
    end

    test do
      title 'Patient IDs match those expected in Group'
      description <<~DESCRIPTION
        This test checks that the list of patient IDs that are expected match those that are returned.
        If no patient ids are provided to the test, then the test will be omitted.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient'

      run {}
    end

    test do
      title 'AllergyIntolerance resources returned conform to the US Core AllergyIntolerance Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-allergyintolerance'

      run {}
    end

    test do
      title 'CarePlan resources returned conform to the US Core CarePlan Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-careplan'

      run {}
    end

    test do
      title 'CareTeam resources returned conform to the US Core CareTeam Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-careteam'

      run {}
    end

    test do
      title 'Condition resources returned conform to the US Core Condition Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-condition'

      run {}
    end

    test do
      title 'Device resources returned conform to the US Core Implantable Device Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-implantable-device'

      run {}
    end

    test do
      title 'DiagnosticReport resources returned conform to the US Core DiagnosticReport Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the following US Core profiles. This includes checking for missing data elements and value set verification.

        * http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-lab
        * http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-note
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-l'

      run {}
    end

    test do
      title 'DocumentReference resources returned conform to the US Core DocumentReference Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-documentreference'

      run {}
    end

    test do
      title 'Goal resources returned conform to the US Core Goal Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-goal'

      run {}
    end

    test do
      title 'Immunization resources returned conform to the US Core Immunization Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-Immunization'

      run {}
    end

    test do
      title 'MedicationRequest resources returned conform to the US Core MedicationRequest Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-medicationrequest'

      run {}
    end

    test do
      title 'Observation resources returned conform to the US Core Observation Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data
        export conform to the following US Core profiles. This includes
        checking for missing data elements and value set verification.

        * http://hl7.org/fhir/us/core/StructureDefinition/pediatric-bmi-for-age
        * http://hl7.org/fhir/us/core/StructureDefinition/pediatric-weight-for-height
        * http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-lab
        * http://hl7.org/fhir/us/core/StructureDefinition/us-core-pulse-oximetry
        * http://hl7.org/fhir/us/core/StructureDefinition/us-core-smokingstatus
        * http://hl7.org/fhir/us/core/StructureDefinition/head-occipital-frontal-circumference-percentile
        * http://hl7.org/fhir/StructureDefinition/bp
        * http://hl7.org/fhir/StructureDefinition/bodyheight
        * http://hl7.org/fhir/StructureDefinition/bodytemp
        * http://hl7.org/fhir/StructureDefinition/bodyweight
        * http://hl7.org/fhir/StructureDefinition/heartrate
        * http://hl7.org/fhir/StructureDefinition/resprate
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-lab'

      run {}
    end

    test do
      title 'Procedure resources returned conform to the US Core Procedure Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-procedure'

      run {}
    end

    test do
      title 'Encounter resources returned conform to the US Core Encounter Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-encounter'

      run {}
    end

    test do
      title 'Organization resources returned conform to the US Core Organization Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-organization'

      run {}
    end

    test do
      title 'Practitioner resources returned conform to the US Core Practitioner Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitioner'

      run {}
    end

    test do
      title 'Provenance resources returned conform to the US Core Provenance Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-provenance'

      run {}
    end

    test do
      title 'Location resources returned conform to the US Core Location Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-location'

      run {}
    end

    test do
      title 'Medication resources returned conform to the US Core Medication Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-medication'

      run {}
    end
  end
end
