module ONCProgram
  class EHRSMARTDiscovery < Inferno::TestGroup
    title 'SMART on FHIR Discovery'
    description <<~DESCRIPTION
      # Background

      The #{title} Sequence test looks for authorization endpoints and SMART
      capabilities as described by the [SMART App Launch
      Framework](http://hl7.org/fhir/smart-app-launch/).

      # Test Methodology

      This test suite performs two HTTP GETs to examine the SMART on FHIR configuration contained
      in both the `/metadata` and `/.well-known/smart-configuration`
      endpoints.  It ensures that all required fields are present, and that information
      provided is consistent between the two endpoints.  These tests currently require both endpoints
      to be implemented to ensure maximum compatibility with existing clients.

      Optional fields are not required and these tests do NOT flag warnings if they are not
      present.

      For more information regarding SMART App Launch discovery, see:

      * [SMART App Launch Framework](http://hl7.org/fhir/smart-app-launch/index.html)
    DESCRIPTION

    id :ehr_smart_discovery

    input :onc_ehr_url
    output :oauth_authorize_endpoint, :oauth_token_endpoint, :oauth_register_endpoint

    def required_well_known_fields
      [
        'authorization_endpoint',
        'token_endpoint',
        'capabilities'
      ]
    end

    test do
      title 'FHIR server makes SMART configuration available from well-known endpoint'
      description <<~DESCRIPTION
        The authorization endpoints accepted by a FHIR resource server can
        be exposed as a Well-Known Uniform Resource Identifier
      DESCRIPTION
      # link 'http://www.hl7.org/fhir/smart-app-launch/conformance/#using-well-known'

      run {}
    end

    test do
      title 'Well-known configuration contains required fields'
      description <<~DESCRIPTION
        The JSON from .well-known/smart-configuration contains the following
        required fields: #{required_well_known_fields.map { |field| "`#{field}`" }.join(', ')}
      DESCRIPTION
      # link 'http://hl7.org/fhir/smart-app-launch/conformance/index.html#metadata'

      run {}
    end

    test do
      title 'Capability Statement provides OAuth 2.0 endpoints'
      description <<~DESCRIPTION
        If a server requires SMART on FHIR authorization for access, its
        metadata must support automated discovery of OAuth2 endpoints.
      DESCRIPTION
      # link 'http://hl7.org/fhir/smart-app-launch/conformance/index.html#using-cs'

      run {}
    end

    test do
      title 'OAuth 2.0 Endpoints in the conformance statement match those from the well-known configuration'
      description <<~DESCRIPTION
        If a server requires SMART on FHIR authorization for access, its
        metadata must support automated discovery of OAuth2 endpoints.
      DESCRIPTION
      # link 'http://hl7.org/fhir/smart-app-launch/conformance/index.html#using-cs'

      run {}
    end

    test do
      title 'Well-known configuration declares support for required capabilities'
      description <<~DESCRIPTION
        A SMART on FHIR server SHALL convey its capabilities to app
        developers by listing the SMART core capabilities supported by
        their implementation within the Well-known configuration file.
        This test ensures that the capabilities required by this scenario
        are properly documented in the Well-known file.
      DESCRIPTION
      # link 'http://hl7.org/fhir/smart-app-launch/conformance/index.html#core-capabilities'

      run {}
    end
  end
end
