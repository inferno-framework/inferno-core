module IPS
  class Organization < Inferno::TestGroup
    title 'Organization (IPS) Tests'
    description 'Verify support for the server capabilities required by the Organization (IPS) profile.'
    id :ips_organization

    test do
      title 'Server returns correct Organization resource from the Organization read interaction'
      description %(
        This test will verify that Organization resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Organization-uv-ips'

      input :organization_id
      makes_request :organization

      run do
        fhir_read(:organization, organization_id, name: :organization)

        assert_response_status(200)
        assert_resource_type(:organization)
        assert resource.id == organization_id,
               "Requested resource with id #{organization_id}, received resource with id #{resource.id}"
      end
    end

    test do
      title 'Server returns Organization resource that matches the Organization (IPS) profile'
      description %(
        This test will validate that the Organization resource returned from the server matches the Organization (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Organization-uv-ips'
      uses_request :organization

      run do
        assert_valid_resource(profile_url: 'http://hl7.org/fhir/uv/ips/StructureDefinition/Organization-uv-ips')
      end
    end
  end
end
