module ONCProgram
  class SinglePatientAPI < Inferno::TestGroup
    title 'Single Patient API'
    description <<~DESCRIPTION
      For each of the relevant USCDI data elements provided in the
      conformance statement, this test executes the [required supported
      searches](https://www.hl7.org/fhir/us/core/CapabilityStatement-us-core-server.html)
      as defined by the US Core Implementation Guide v3.1.  The test begins
      by searching by one or more patients, with the expectation that the
      Bearer token provided to the test grants access to all USCDI
      resources. It uses results returned from that query to generate other
      queries and checks that the results are consistent with the provided
      search parameters.  It then performs a read on each Resource returned
      and validates the response against the relevant
      [profile](https://www.hl7.org/fhir/us/core/profiles.html) as currently
      defined in the US Core Implementation Guide. All MUST SUPPORT elements
      must be seen before the test can pass, as well as Data Absent Reason
      to demonstrate that the server can properly handle missing data. Note that
      Encounter, Organization and Practitioner resources must be accessible as
      references in some US Core profiles to satisfy must support
      requirements, and those references will be validated to their US Core profile.
      These resources will not be tested for FHIR search support.
    DESCRIPTION

    id :single_patient_api

    group from: :us_core_capability_statement
    group from: :us_core_patient
    group from: :us_core_allergy_intolerance
    group from: :us_core_care_plan
    group from: :us_core_care_team
    group from: :us_core_condition
    group from: :us_core_implantable_device
    group from: :us_core_diagnostic_report_note
    group from: :us_core_diagnostic_report_lab
    group from: :us_core_document_reference
    group from: :us_core_goal
    group from: :us_core_immunization
    group from: :us_core_medication_request
    group from: :us_core_smoking_status
    group from: :us_core_pediatric_weight_for_height
    group from: :us_core_observation_lab
    group from: :us_core_pediatric_bmi_for_age
    group from: :us_core_pulse_oximetry
    group from: :us_core_body_height
    group from: :us_core_body_temp
    group from: :us_core_bp
    group from: :us_core_body_weight
    group from: :us_core_head_circumference
    group from: :us_core_heart_rate
    group from: :us_core_resp_rate
    group from: :us_core_procedure
    group from: :us_core_clinical_notes
    group from: :us_core_encounter
    group from: :us_core_organization
    group from: :us_core_practitioner
    group from: :us_core_provenance
    group from: :us_core_data_absent_reason
  end
end
