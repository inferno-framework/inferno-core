module IPS
  class Immunization < Inferno::TestGroup
    title 'Immunization (IPS) Tests'
    description 'Verify support for the server capabilities required by the Immunization (IPS) profile.'
    id :ips_immunization

    input :immunization_id

    test do
      title 'Server returns correct Immunization resource from the Immunization read interaction'
      description %(
        This test will verify that Immunization resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Immunization-uv-ips'
    end

    test do
      title 'Server returns Immunization resource that matches the Immunization (IPS) profile'
      description %(
        This test will validate that the Immunization resource returned from the server matches the Immunization (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Immunization-uv-ips'
    end
  end
end
