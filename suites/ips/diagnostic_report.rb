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
    end

    test do
      title 'Server returns DiagnosticReport resource that matches the DiagnosticReport (IPS) profile'
      description %(
        This test will validate that the DiagnosticReport resource returned from the server matches the DiagnosticReport (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/DiagnosticReport-uv-ips'
    end
  end
end
