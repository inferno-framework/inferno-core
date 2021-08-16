module SMART
  class AppRedirectTest < Inferno::Test
    title 'OAuth server redirects client browser to app redirect URI'
    description %(
      Client browser redirected from OAuth server to redirect URI of client
      app as described in SMART authorization sequence.
    )
    id :smart_app_redirect

    input :client_id,
          title: 'Client ID',
          description: 'Client ID provided during registration of Inferno as a standalone application',
          default: 'SAMPLE_PUBLIC_CLIENT_ID'
    input :requested_scopes,
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
          ).gsub(/\s{2,}/, ' ')
    input :url,
          title: 'FHIR Endpoint',
          description: 'URL of the FHIR endpoint used by standalone applications',
          default: 'https://inferno.healthit.gov/reference-server/r4'
    input :smart_authorization_url

    output :state
    receives_request :standalone_redirect

    run do
      assert_valid_http_uri(
        smart_authorization_url,
        "OAuth2 Authorization Endpoint '#{smart_authorization_url}' is not a valid URI"
      )

      output state: SecureRandom.uuid

      oauth2_params = {
        'response_type' => 'code',
        'client_id' => client_id,
        'redirect_uri' => redirect_uri,
        'scope' => requested_scopes,
        'state' => state,
        'aud' => url
      }

      authorization_url = smart_authorization_url

      authorization_url +=
        if authorization_url.include? '?'
          '&'
        else
          '?'
        end

      oauth2_params.each do |key, value|
        authorization_url += "#{key}=#{CGI.escape(value)}&"
      end

      authorization_url.chomp!('&')

      wait(
        identifier: state,
        message: %(
          Redirect to: #{authorization_url} Waiting to receive a request
          at /custom/smart/redirect with a state of `#{state}`.
        )
      )
    end
  end
end
