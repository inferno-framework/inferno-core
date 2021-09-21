module SMART
  class OpenIDFHIRUserClaimTest < Inferno::Test
    id :smart_openid_fhir_user_claim
    title 'ID token contains a valid fhirUser claim'
    description %(
        Verify that the `fhirUser` claim is present in the ID token. The
        `fhirUser` claim must be the url for a Patient, Practitioner,
        RelatedPerson, or Person resource.
      )

    input :id_token_payload_json, :requested_scopes
    output :id_token_fhir_user

    run do
      skip_if id_token_payload_json.blank?
      skip_if !requested_scopes&.include?('fhirUser'), '`fhirUser` scope not requested'

      payload = JSON.parse(id_token_payload_json)
      fhir_user = payload['fhirUser']

      valid_fhir_user_resource_types = ['Patient', 'Practitioner', 'RelatedPerson', 'Person']

      assert fhir_user.present?, 'ID token does not contain `fhirUser` claim'
      assert valid_fhir_user_resource_types.any? { |type| fhir_user.include? type },
             "ID token `fhirUser` claim does not refer to a valid resource type: #{fhir_user}"

      output id_token_fhir_user: fhir_user
    end
  end
end
