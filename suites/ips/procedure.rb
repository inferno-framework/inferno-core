module IPS
  class Procedure < Inferno::TestGroup
    title 'Procedure (IPS) Tests'
    description 'Verify support for the server capabilities required by the Procedure (IPS) profile.'
    id :ips_procedure

    input :procedure_id

    test do
      title 'Server returns correct Procedure resource from the Procedure read interaction'
      description %(
        This test will verify that Procedure resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Procedure-uv-ips'
      makes_request :procedure

      run do
        fhir_read(:procedure, procedure_id, name: :procedure)

        assert_response_status(200)
        assert_resource_type(:procedure)
        assert resource.id == procedure_id,
               "Requested resource with id #{procedure_id}, received resource with id #{resource.id}"
      end
    end

    test do
      title 'Server returns Procedure resource that matches the Procedure (IPS) profile'
      description %(
        This test will validate that the Procedure resource returned from the server matches the Procedure (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Procedure-uv-ips'
      uses_request :procedure

      run do
        assert_valid_resource(profile_url: 'http://hl7.org/fhir/uv/ips/StructureDefinition/Procedure-uv-ips')
      end
    end
  end
end
