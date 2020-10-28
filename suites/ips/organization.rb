module IPS
  class Organization < Inferno::TestGroup
    title 'Organization (IPS) Tests'
    description 'Verify support for the server capabilities required by the Organization (IPS) profile.'
    id :ips_organization

    input :organization_id

    test do
      title 'Server returns correct Organization resource from the Organization read interaction'
      description %(
        This test will verify that Organization resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Organization-uv-ips'
    end

    test do
      title 'Server returns Organization resource that matches the Organization (IPS) profile'
      description %(
        This test will validate that the Organization resource returned from the server matches the Organization (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Organization-uv-ips'
    end
  end
end
