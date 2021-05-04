module IPS
  class DeviceUseStatement < Inferno::TestGroup
    title 'Device Use Statement (IPS) Tests'
    description 'Verify support for the server capabilities required by the Device Use Statement (IPS) profile.'
    id :ips_device_use_statement

    input :device_use_statement_id

    test do
      title 'Server returns correct DeviceUseStatement resource from the DeviceUseStatement read interaction'
      description %(
        This test will verify that DeviceUseStatement resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/DeviceUseStatement-uv-ips'
      makes_request :device_use_statement

      run do
        fhir_read(:device_use_statement, device_use_statement_id, name: :device_use_statement)

        assert_response_status(200)
        assert_resource_type(:device_use_statement)
        assert resource.id == device_use_statement_id,
               "Requested resource with id #{device_use_statement_id}, received resource with id #{resource.id}"
      end
    end

    test do
      title 'Server returns DeviceUseStatement resource that matches the Device Use Statement (IPS) profile'
      description %(
        This test will validate that the DeviceUseStatement resource returned from the server matches the Device Use Statement (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/DeviceUseStatement-uv-ips'
      uses_request :device_use_statement

      run do
        assert_valid_resource(profile_url: 'http://hl7.org/fhir/uv/ips/StructureDefinition/DeviceUseStatement-uv-ips')
      end
    end
  end
end
