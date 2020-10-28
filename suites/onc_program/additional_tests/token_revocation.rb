module ONCProgram
  class TokenRevocation < Inferno::TestGroup
    title 'Token Revocation'
    description <<~DESCRIPTION
      Demonstrate the Health IT module is capable of revoking access granted to an application.
    DESCRIPTION

    id :token_revocation

    input :onc_sl_url, :onc_sl_token, :onc_sl_refresh_token, :onc_sl_patient_id, :onc_sl_oauth_token_endpoint,
          :onc_visual_token_revocation, :onc_visual_token_revocation_notes

    test do
      title 'Health IT developer demonstrated the ability of the Health IT Module to revoke tokens.'
      description <<~DESCRIPTION
        Health IT developer demonstrated the ability of the Health IT Module / authorization server to revoke tokens.
      DESCRIPTION
      # link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'

      run {}
    end

    test do
      title 'Access to Patient resource returns unauthorized after token revocation.'
      description <<~DESCRIPTION
        This test checks that the Patient resource returns unuathorized after token revocation.
      DESCRIPTION
      # link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'

      run {}
    end

    test do
      title 'Token refresh fails after token revocation.'
      description <<~DESCRIPTION
        This test checks that refreshing token fails after token revokation.
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/'

      run {}
    end
  end
end
