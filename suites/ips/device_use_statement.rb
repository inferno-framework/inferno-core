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
    end

    test do
      title 'Server returns DeviceUseStatement resource that matches the Device Use Statement (IPS) profile'
      description %(
        This test will validate that the DeviceUseStatement resource returned from the server matches the Device Use Statement (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/DeviceUseStatement-uv-ips'
    end
  end
end
