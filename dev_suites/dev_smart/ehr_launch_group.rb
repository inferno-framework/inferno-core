require_relative 'app_launch_test'
require_relative 'app_redirect_test'
require_relative 'code_received_test'
require_relative 'launch_received_test'
require_relative 'token_exchange_test'
require_relative 'token_response_body_test'
require_relative 'token_response_headers_test'

module SMART
  class EHRLaunchGroup < Inferno::TestGroup
    id :smart_ehr_launch
    title 'SMART EHR Launch'

    description %(
      # Background

      The [EHR
      Launch](http://hl7.org/fhir/smart-app-launch/index.html#ehr-launch-sequence)
      is one of two ways in which an app can be launched, the other being
      Standalone launch. In an EHR launch, the app is launched from an
      existing EHR session or portal by a redirect to the registered launch
      URL. The EHR provides the app two parameters:

      * `iss` - Which contains the FHIR server url
      * `launch` - An identifier needed for authorization

      # Test Methodology

      Inferno will wait for the EHR server redirect upon execution. When the
      redirect is received Inferno will check for the presence of the `iss`
      and `launch` parameters. The security of the authorization endpoint is
      then checked and authorization is attempted using the provided `launch`
      identifier.

      For more information on the #{title} see:

      * [SMART EHR Launch Sequence](http://hl7.org/fhir/smart-app-launch/index.html#ehr-launch-sequence)
    )

    config(
      inputs: {
        client_id: {
          name: :ehr_client_id,
          title: 'EHR Launch Client ID',
          description: 'Client ID provided during registration of Inferno as an EHR launch application',
          default: 'SAMPLE_PUBLIC_CLIENT_ID'
        },
        client_secret: {
          name: :ehr_client_secret,
          title: 'EHR Launch Client Secret',
          description: 'Client Secret provided during registration of Inferno as an EHR launch application'
        },
        requested_scopes: {
          name: :ehr_requested_scopes,
          title: 'EHR Launch Scope',
          description: 'OAuth 2.0 scope provided by system to enable all required functionality',
          type: 'textarea',
          default: %(
            launch openid fhirUser offline_access
            patient/Medication.read patient/AllergyIntolerance.read
            patient/CarePlan.read patient/CareTeam.read patient/Condition.read
            patient/Device.read patient/DiagnosticReport.read
            patient/DocumentReference.read patient/Encounter.read
            patient/Goal.read patient/Immunization.read patient/Location.read
            patient/MedicationRequest.read patient/Observation.read
            patient/Organization.read patient/Patient.read
            patient/Practitioner.read patient/Procedure.read
            patient/Provenance.read patient/PractitionerRole.read
          ).gsub(/\s{2,}/, ' ').strip
        },
        url: {
          title: 'EHR Launch FHIR Endpoint',
          description: 'URL of the FHIR endpoint used by EHR launched applications',
          default: 'https://inferno.healthit.gov/reference-server/r4'
        },
        code: {
          name: :ehr_code
        },
        state: {
          name: :ehr_state
        },
        launch: {
          name: :ehr_launch
        }
      },
      outputs: {
        launch: { name: :ehr_launch },
        code: { name: :ehr_code },
        token_retrieval_time: { name: :ehr_token_retrieval_time },
        state: { name: :ehr_state },
        id_token: { name: :ehr_id_token },
        refresh_token: { name: :ehr_refresh_token },
        access_token: { name: :ehr_access_token },
        expires_in: { name: :ehr_expires_in },
        patient_id: { name: :ehr_patient_id },
        encounter_id: { name: :ehr_encounter_id },
        received_scopes: { name: :ehr_received_scopes },
        intent: { name: :ehr_intent }
      },
      requests: {
        launch: { name: :ehr_launch },
        redirect: { name: :ehr_redirect },
        token: { name: :ehr_token }
      }
    )

    test from: :smart_app_launch
    test from: :smart_launch_received
    test from: :smart_app_redirect do
      input :launch
    end
    test from: :smart_code_received
    test from: :smart_token_exchange
    test from: :smart_token_response_body
    test from: :smart_token_response_headers
  end
end
