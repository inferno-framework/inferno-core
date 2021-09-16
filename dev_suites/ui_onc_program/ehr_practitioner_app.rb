Dir.glob(File.join(__dir__, 'ehr_practitioner_app', '*.rb')).each { |path| require_relative path.delete_prefix("#{__dir__}/") }

module ONCProgram
  class EHRPractitionerApp < Inferno::TestGroup
    title 'EHR Practitioner App'
    description <<~DESCRIPTION
      Demonstrate the ability to perform an EHR launch to a [SMART on
      FHIR](http://www.hl7.org/fhir/smart-app-launch/) confidential client
      with patient context, refresh token, and [OpenID Connect
      (OIDC)](https://openid.net/specs/openid-connect-core-1_0.html)
      identity token.  After launch, a simple Patient resource read is
      performed on the patient in context.  The access token is then
      refreshed, and the Patient resource is read using the new access token
      to ensure that the refresh was successful.  Finally, the
      authentication information provided by OpenID Connect is decoded and
      validated.
    DESCRIPTION

    id :ehr_practitioner_app

    group from: :ehr_smart_discovery
    group from: :ehr_launch
    group from: :ehr_openid_connect
    group from: :ehr_token_refresh
  end
end
