module IPS
  class Specimen < Inferno::TestGroup
    title 'Specimen (IPS) Tests'
    description 'Verify support for the server capabilities required by the Specimen (IPS) profile.'
    id :ips_specimen

    input :specimen_id

    test do
      title 'Server returns correct Specimen resource from the Specimen read interaction'
      description %(
        This test will verify that Specimen resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Specimen-uv-ips'
    end

    test do
      title 'Server returns Specimen resource that matches the Specimen (IPS) profile'
      description %(
        This test will validate that the Specimen resource returned from the server matches the Specimen (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Specimen-uv-ips'
    end
  end
end
