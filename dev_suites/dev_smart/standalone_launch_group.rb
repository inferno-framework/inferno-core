require_relative 'app_redirect_test'
require_relative 'code_received_test'
require_relative 'token_exchange_test'
require_relative 'token_response_body_test'
require_relative 'token_response_headers_test'

module SMART
  class StandaloneLaunchGroup < Inferno::TestGroup
    id :smart_standalone_launch
    title 'SMART Standalone Launch'

    description %(
      # Background

      The [Standalone
      Launch](http://hl7.org/fhir/smart-app-launch/#standalone-launch-sequence)
      Sequence allows an app, like Inferno, to be launched independent of an
      existing EHR session. It is one of the two launch methods described in
      the SMART App Launch Framework alongside EHR Launch. The app will
      request authorization for the provided scope from the authorization
      endpoint, ultimately receiving an authorization token which can be used
      to gain access to resources on the FHIR server.

      # Test Methodology

      Inferno will redirect the user to the the authorization endpoint so that
      they may provide any required credentials and authorize the application.
      Upon successful authorization, Inferno will exchange the authorization
      code provided for an access token.

      For more information on the #{title}:

      * [Standalone Launch Sequence](http://hl7.org/fhir/smart-app-launch/#standalone-launch-sequence)
    )

    config(
      inputs: {
        client_id: {
          name: :standalone_client_id,
          title: 'Standalone Client ID',
          description: 'Client ID provided during registration of Inferno as a standalone application',
          default: 'SAMPLE_PUBLIC_CLIENT_ID'
        },
        client_secret: {
          name: :standalone_client_secret,
          title: 'Standalone Client Secret',
          description: 'Client Secret provided during registration of Inferno as a standalone application'
        },
        requested_scopes: {
          name: :standalone_requested_scopes,
          title: 'Standalone Scope',
          description: 'OAuth 2.0 scope provided by system to enable all required functionality',
          type: 'textarea',
          default: %(
            launch/patient openid fhirUser offline_access
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
          title: 'Standalone FHIR Endpoint',
          description: 'URL of the FHIR endpoint used by standalone applications',
          default: 'https://inferno.healthit.gov/reference-server/r4'
        },
        code: {
          name: :standalone_code
        },
        state: {
          name: :standalone_state
        }
      },
      outputs: {
        code: { name: :standalone_code },
        token_retrieval_time: { name: :standalone_token_retrieval_time },
        state: { name: :standalone_state },
        id_token: { name: :standalone_id_token },
        refresh_token: { name: :standalone_refresh_token },
        access_token: { name: :standalone_access_token },
        expires_in: { name: :standalone_expires_in },
        patient_id: { name: :standalone_patient_id },
        encounter_id: { name: :standalone_encounter_id },
        received_scopes: { name: :standalone_received_scopes },
        intent: { name: :standalone_intent }
      },
      requests: {
        redirect: { name: :standalone_redirect },
        token: { name: :standalone_token }
      }
    )

    test from: :smart_app_redirect
    test from: :smart_code_received
    test from: :smart_token_exchange
    test from: :smart_token_response_body
    test from: :smart_token_response_headers
  end
end
