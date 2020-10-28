module IPS
  class Condition < Inferno::TestGroup
    title 'Condition (IPS) Tests'
    description 'Verify support for the server capabilities required by the Condition (IPS) profile.'
    id :ips_condition

    input :condition_id

    test do
      title 'Server returns correct Condition resource from the Condition read interaction'
      description %(
        This test will verify that Condition resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Condition-uv-ips'
    end

    test do
      title 'Server returns Condition resource that matches the Condition (IPS) profile'
      description %(
        This test will validate that the Condition resource returned from the server matches the Condition (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Condition-uv-ips'
    end
  end
end
