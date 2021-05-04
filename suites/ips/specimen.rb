module IPS
  class Specimen < Inferno::TestGroup
    title 'Specimen (IPS) Tests'
    description 'Verify support for the server capabilities required by the Specimen (IPS) profile.'
    id :ips_specimen

    input :specimen_id

    test do
      title 'Server returns correct Specimen resource from the Specimen read interaction'
      description %(
        This test will verify that Specimen resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Specimen-uv-ips'
      makes_request :specimen

      run do
        fhir_read(:specimen, specimen_id, name: :specimen)

        assert_response_status(200)
        assert_resource_type(:specimen)
        assert resource.id == specimen_id,
               "Requested resource with id #{specimen_id}, received resource with id #{resource.id}"
      end
    end

    test do
      title 'Server returns Specimen resource that matches the Specimen (IPS) profile'
      description %(
        This test will validate that the Specimen resource returned from the server matches the Specimen (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Specimen-uv-ips'
      uses_request :specimen

      run do
        assert_valid_resource(profile_url: 'http://hl7.org/fhir/uv/ips/StructureDefinition/Specimen-uv-ips')
      end
    end
  end
end
