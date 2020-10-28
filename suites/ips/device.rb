module IPS
  class Device < Inferno::TestGroup
    title 'Device (IPS) Tests'
    description 'Verify support for the server capabilities required by the Device (IPS) profile.'
    id :ips_device

    input :device_id

    test do
      title 'Server returns correct Device resource from the Device read interaction'
      description %(
        This test will verify that Device resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Device-uv-ips'
    end

    test do
      title 'Server returns Device resource that matches the Device (IPS) profile'
      description %(
        This test will validate that the Device resource returned from the server matches the Device (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Device-uv-ips'
    end
  end
end
