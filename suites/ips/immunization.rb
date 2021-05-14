module IPS
  class Immunization < Inferno::TestGroup
    title 'Immunization (IPS) Tests'
    description 'Verify support for the server capabilities required by the Immunization (IPS) profile.'
    id :ips_immunization

    test do
      title 'Server returns correct Immunization resource from the Immunization read interaction'
      description %(
        This test will verify that Immunization resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Immunization-uv-ips'

      input :immunization_id
      makes_request :immunization

      run do
        fhir_read(:immunization, immunization_id, name: :immunization)

        assert_response_status(200)
        assert_resource_type(:immunization)
        assert resource.id == immunization_id,
               "Requested resource with id #{immunization_id}, received resource with id #{resource.id}"
      end
    end

    test do
      title 'Server returns Immunization resource that matches the Immunization (IPS) profile'
      description %(
        This test will validate that the Immunization resource returned from the server matches the Immunization (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Immunization-uv-ips'
      uses_request :immunization

      run do
        assert_valid_resource(profile_url: 'http://hl7.org/fhir/uv/ips/StructureDefinition/Immunization-uv-ips')
      end
    end
  end
end
