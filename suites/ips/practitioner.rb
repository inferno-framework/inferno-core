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
      makes_request :practitioner

      run do
        fhir_read(:practitioner, practitioner_id, name: :practitioner)

        assert_response_status(200)
        assert_resource_type(:practitioner)
        assert resource.id == practitioner_id,
               "Requested resource with id #{practitioner_id}, received resource with id #{resource.id}"
      end
    end

    test do
      title 'Server returns Practitioner resource that matches the Practitioner (IPS) profile'
      description %(
        This test will validate that the Practitioner resource returned from the server matches the Practitioner (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Practitioner-uv-ips'
      uses_request :practitioner

      run do
        assert_valid_resource(profile_url: 'http://hl7.org/fhir/uv/ips/StructureDefinition/Practitioner-uv-ips')
      end
    end
  end
end
