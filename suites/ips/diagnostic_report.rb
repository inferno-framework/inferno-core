module IPS
  class DiagnosticReport < Inferno::TestGroup
    title 'DiagnosticReport (IPS) Tests'
    description 'Verify support for the server capabilities required by the DiagnosticReport (IPS) profile.'
    id :ips_diagnostic_report

    input :diagnostic_report_id

    test do
      title 'Server returns correct DiagnosticReport resource from the DiagnosticReport read interaction'
      description %(
        This test will verify that DiagnosticReport resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/DiagnosticReport-uv-ips'
      makes_request :diagnostic_report

      run do
        fhir_read(:diagnostic_report, diagnostic_report_id, name: :diagnostic_report)

        assert_response_status(200)
        assert_resource_type(:diagnostic_report)
        assert resource.id == diagnostic_report_id,
               "Requested resource with id #{diagnostic_report_id}, received resource with id #{resource.id}"
      end
    end

    test do
      title 'Server returns DiagnosticReport resource that matches the DiagnosticReport (IPS) profile'
      description %(
        This test will validate that the DiagnosticReport resource returned from the server matches the DiagnosticReport (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/DiagnosticReport-uv-ips'
      uses_request :diagnostic_report

      run do
        assert_valid_resource(profile_url: 'http://hl7.org/fhir/uv/ips/StructureDefinition/DiagnosticReport-uv-ips')
      end
    end
  end
end
