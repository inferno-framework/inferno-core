module IPS
  class Medication < Inferno::TestGroup
    title 'Medication (IPS) Tests'
    description 'Verify support for the server capabilities required by the Medication (IPS) profile.'
    id :ips_medication

    input :medication_id

    test do
      title 'Server returns correct Medication resource from the Medication read interaction'
      description %(
        This test will verify that Medication resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Medication-uv-ips'
    end

    test do
      title 'Server returns Medication resource that matches the Medication (IPS) profile'
      description %(
        This test will validate that the Medication resource returned from the server matches the Medication (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Medication-uv-ips'
    end
  end
end
