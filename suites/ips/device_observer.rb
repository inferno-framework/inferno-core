module IPS
  class DeviceObserver < Inferno::TestGroup
    title 'Device (performer, observer) Tests'
    description 'Verify support for the server capabilities required by the Device (performer, observer) profile.'
    id :ips_device_observer

    test do
      title 'Server returns correct Device resource from the Device read interaction'
      description %(
        This test will verify that Device resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Device-observer-uv-ips'

      input :device_id
      makes_request :device_observer

      run do
        fhir_read(:device, device_id, name: :device_observer)

        assert_response_status(200)
        assert_resource_type(:device)
        assert resource.id == device_id,
               "Requested resource with id #{device_id}, received resource with id #{resource.id}"
      end
    end

    test do
      title 'Server returns Device resource that matches the Device (performer, observer) profile'
      description %(
        This test will validate that the Device resource returned from the server matches the Device (performer, observer) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Device-observer-uv-ips'
      uses_request :device_observer

      run do
        assert_valid_resource(profile_url: 'http://hl7.org/fhir/uv/ips/StructureDefinition/Device-observer-uv-ips')
      end
    end
  end
end
