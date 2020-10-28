module IPS
  class AllergyIntolerance < Inferno::TestGroup
    title 'Allergy Intolerance (IPS) Tests'
    description 'Verify support for the server capabilities required by the Allergy Intolerance (IPS) profile.'
    id :ips_allergy_intolerance

    input :allergy_intolerance_id

    test do
      title 'Server returns correct AllergyIntolerance resource from the AllergyIntolerance read interaction'
      description %(
        This test will verify that AllergyIntolerance resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/AllergyIntolerance-uv-ips'
    end

    test do
      title 'Server returns AllergyIntolerance resource that matches the Allergy Intolerance (IPS) profile'
      description %(
        This test will validate that the AllergyIntolerance resource returned from the server matches the Allergy Intolerance (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/AllergyIntolerance-uv-ips'
    end
  end
end
