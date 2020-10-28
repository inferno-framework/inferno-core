module ONCProgram
  class StandalonePatientAppFullAccess < Inferno::TestGroup
    title 'Standalone Patient App - Full Patient Access'
    description <<~DESCRIPTION
      This scenario demonstrates the ability of a system to perform a Patient
      Standalone Launch to a [SMART on
      FHIR](http://www.hl7.org/fhir/smart-app-launch/) confidential client with
      a patient context, refresh token, and [OpenID Connect
      (OIDC)](https://openid.net/specs/openid-connect-core-1_0.html) identity
      token. After launch, a simple Patient resource read is performed on the
      patient in context. The access token is then refreshed, and the Patient
      resource is read using the new access token to ensure that the refresh was
      successful. The authentication information provided by OpenID Connect is
      decoded and validated, and simple queries are performed to ensure that
      access is granted to all USCDI data elements.
    DESCRIPTION

    id :standalone_patient_app_full_access

    group from: :standalone_smart_discovery
    group from: :standalone_launch
    group from: :standalone_openid_connect
    group from: :standalone_token_refresh
    group from: :access_verify_unrestricted
  end
end
