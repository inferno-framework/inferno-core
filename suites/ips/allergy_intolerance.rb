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
      makes_request :allergy_intolerance

      run do
        fhir_read(:allergy_intolerance, allergy_intolerance_id, name: :allergy_intolerance)

        assert_response_status(200)
        assert_resource_type(:allergy_intolerance)
        assert resource.id == allergy_intolerance_id,
               "Requested resource with id #{allergy_intolerance_id}, received resource with id #{resource.id}"
      end
    end

    test do
      title 'Server returns AllergyIntolerance resource that matches the Allergy Intolerance (IPS) profile'
      description %(
        This test will validate that the AllergyIntolerance resource returned from the server matches the Allergy Intolerance (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/AllergyIntolerance-uv-ips'
      uses_request :allergy_intolerance

      run do
        assert_valid_resource(profile_url: 'http://hl7.org/fhir/uv/ips/StructureDefinition/AllergyIntolerance-uv-ips')
      end
    end
  end
end
