module IPS
  class PractitionerRole < Inferno::TestGroup
    title 'PractitionerRole (IPS) Tests'
    description 'Verify support for the server capabilities required by the PractitionerRole (IPS) profile.'
    id :ips_practitioner_role

    input :practitioner_role_id

    test do
      title 'Server returns correct PractitionerRole resource from the PractitionerRole read interaction'
      description %(
        This test will verify that PractitionerRole resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/PractitionerRole-uv-ips'
      makes_request :practitioner_role

      run do
        fhir_read(:practitioner_role, practitioner_role_id, name: :practitioner_role)

        assert_response_status(200)
        assert_resource_type(:practitioner_role)
        assert resource.id == practitioner_role_id,
               "Requested resource with id #{practitioner_role_id}, received resource with id #{resource.id}"
      end
    end

    test do
      title 'Server returns PractitionerRole resource that matches the PractitionerRole (IPS) profile'
      description %(
        This test will validate that the PractitionerRole resource returned from the server matches the PractitionerRole (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/PractitionerRole-uv-ips'
      uses_request :practitioner_role

      run do
        assert_valid_resource(profile_url: 'http://hl7.org/fhir/uv/ips/StructureDefinition/PractitionerRole-uv-ips')
      end
    end
  end
end
