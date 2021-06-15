module ONCProgram
  class ONCVisualInspection < Inferno::TestGroup
    title 'Visual Inspection and Attestation'
    description <<~DESCRIPTION
      Verify conformance to portions of the test procedure that are not automated.
    DESCRIPTION

    input :onc_visual_single_registration,
          :onc_visual_single_registration_notes,
          :onc_visual_multi_registration,
          :onc_visual_multi_registration_notes,
          :onc_visual_single_scopes,
          :onc_visual_single_scopes_notes,
          :onc_visual_single_offline_access,
          :onc_visual_single_offline_access_notes,
          :onc_visual_refresh_timeout,
          :onc_visual_refresh_timeout_notes,
          :onc_visual_introspection,
          :onc_visual_introspection_notes,
          :onc_visual_data_without_omission,
          :onc_visual_data_without_omission_notes,
          :onc_visual_multi_scopes_no_greater,
          :onc_visual_multi_scopes_no_greater_notes,
          :onc_visual_documentation,
          :onc_visual_documentation_notes,
          :onc_visual_jwks_cache,
          :onc_visual_jwks_cache_notes,
          :onc_visual_jwks_token_revocation,
          :onc_visual_jwks_token_revocation_notes,
          :onc_visual_patient_period,
          :onc_visual_patient_period_notes,
          :onc_visual_native_application,
          :onc_visual_native_application_notes

    id :onc_visual_inspection

    test do
      title 'Health IT Module demonstrated support for application registration for single patients.'
      description <<~DESCRIPTION
        Health IT Module demonstrated support for application registration for single patients.
      DESCRIPTION
      # link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'

      run {}
    end

    test do
      title 'Health IT Module demonstrated support for application registration for multiple patients.'
      description <<~DESCRIPTION
        Health IT Module demonstrated support for supports application registration for multiple patients.
      DESCRIPTION
      # link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'

      run {}
    end

    test do
      title 'Health IT Module demonstrated a graphical user interface for user to authorize FHIR resources.'
      description <<~DESCRIPTION
        Health IT Module demonstrated a graphical user interface for user to authorize FHIR resources
      DESCRIPTION
      # link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'

      run {}
    end

    test do
      title 'Health IT Module demonstrated a graphical user interface to authorize offline access.'
      description <<~DESCRIPTION
        Health IT Module demonstrated a graphical user interface for user to authorize offline access.
      DESCRIPTION
      # link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'

      run {}
    end

    test do
      title 'Health IT Module attested that refresh tokens had three month timeout period.'
      description <<~DESCRIPTION
        Health IT Module attested that refresh tokens had three month timeout period.
      DESCRIPTION
      # link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'

      run {}
    end

    test do
      title 'Health IT developer demonstrated the ability of the Health IT Module / authorization server to validate token it has issued.'
      description <<~DESCRIPTION
        Health IT developer demonstrated the ability of the Health IT Module / authorization server to validate token it has issued
      DESCRIPTION
      # link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'

      run {}
    end

    test do
      title 'Tester verifies that all information is accurate and without omission.'
      description <<~DESCRIPTION
        Tester verifies that all information is accurate and without omission.
      DESCRIPTION
      # link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'

      run {}
    end

    test do
      title 'Information returned no greater than scopes pre-authorized for multi-patient queries.'
      description <<~DESCRIPTION
        Information returned no greater than scopes pre-authorized for multi-patient queries.
      DESCRIPTION
      # link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'

      run {}
    end

    test do
      title 'Health IT developer demonstrated the documentation is available at a publicly accessible URL.'
      description <<~DESCRIPTION
        Health IT developer demonstrated the documentation is available at a publicly accessible URL.
      DESCRIPTION
      # link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'

      run {}
    end

    test do
      title 'Health IT developer confirms the Health IT module does not cache the JWK Set received via a TLS-protected URL for longer than the cache-control header received by an application indicates.'
      description <<~DESCRIPTION
        The Health IT developer confirms the Health IT module does not cache the JWK Set received via a TLS-protected URL for longer than the cache-control header indicates.
      DESCRIPTION
      # link 'https://www.federalregister.gov/documents/2020/05/01/2020-07419/21st-century-cures-act-interoperability-information-blocking-and-the-onc-health-it-certification'

      run {}
    end

    test do
      title 'Health IT developer demonstrates support for the Patient Demographics Suffix USCDI v1 element.'
      description <<~DESCRIPTION
        ONC certification criteria states that all USCDI v1 data classes and elements need to be supported, including Patient
        Demographics - Suffix.However, US Core v3.1.1 does not tag the relevant element
        (Patient.name.suffix) as MUST SUPPORT. The Health IT developer must demonstrate support
        for this USCDI v1 element as described in the US Core Patient Profile implementation guidance.
      DESCRIPTION
      # link 'https://www.healthit.gov/isa/united-states-core-data-interoperability-uscdi'

      run {}
    end

    test do
      title 'Health IT developer demonstrates support for the Patient Demographics Previous Name USCDI v1 element.'
      description <<~DESCRIPTION
        ONC certification criteria states that all USCDI v1 data classes and elements need to be supported, including Patient
        Demographics - Previous Name. However, US Core v3.1.1 does not tag the relevant element
        (Patient.name.period) as MUST SUPPORT. The Health IT developer must demonstrate support
        for this USCDI v1 element as described in the US Core Patient Profile implementation guidance.
      DESCRIPTION
      # link 'https://www.healthit.gov/isa/united-states-core-data-interoperability-uscdi'

      run {}
    end

    test do
      title 'Health IT developer demonstrates support for issuing refresh tokens to native applications.'
      description <<~DESCRIPTION
        The health IT developer demonstrates the ability of the Health IT
        Module to grant a refresh token valid for a period of no less
        than three months to native applications capable of storing a
        refresh token.

        This cannot be tested in an automated way because the health IT
        developer may require use of additional security mechanisms within
        the OAuth 2.0 authorization flow to ensure authorization is sufficiently
        secure for native applications.
      DESCRIPTION
      # link 'https://www.federalregister.gov/documents/2020/11/04/2020-24376/information-blocking-and-the-onc-health-it-certification-program-extension-of-compliance-dates-and'

      run {}
    end
  end
end
