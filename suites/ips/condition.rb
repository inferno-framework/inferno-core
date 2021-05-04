module IPS
  class Condition < Inferno::TestGroup
    title 'Condition (IPS) Tests'
    description 'Verify support for the server capabilities required by the Condition (IPS) profile.'
    id :ips_condition

    input :condition_id

    test do
      title 'Server returns correct Condition resource from the Condition read interaction'
      description %(
        This test will verify that Condition resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Condition-uv-ips'
      makes_request :condition

      run do
        fhir_read(:condition, condition_id, name: :condition)

        assert_response_status(200)
        assert_resource_type(:condition)
        assert resource.id == condition_id,
               "Requested resource with id #{condition_id}, received resource with id #{resource.id}"
      end
    end

    test do
      title 'Server returns Condition resource that matches the Condition (IPS) profile'
      description %(
        This test will validate that the Condition resource returned from the server matches the Condition (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Condition-uv-ips'
      uses_request :condition

      run do
        assert_valid_resource(profile_url: 'http://hl7.org/fhir/uv/ips/StructureDefinition/Condition-uv-ips')
      end
    end
  end
end
