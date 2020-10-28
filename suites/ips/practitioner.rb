module IPS
  class Practitioner < Inferno::TestGroup
    title 'Practitioner (IPS) Tests'
    description 'Verify support for the server capabilities required by the Practitioner (IPS) profile.'
    id :ips_practitioner

    input :practitioner_id

    test do
      title 'Server returns correct Practitioner resource from the Practitioner read interaction'
      description %(
        This test will verify that Practitioner resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Practitioner-uv-ips'
    end

    test do
      title 'Server returns Practitioner resource that matches the Practitioner (IPS) profile'
      description %(
        This test will validate that the Practitioner resource returned from the server matches the Practitioner (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Practitioner-uv-ips'
    end
  end
end
