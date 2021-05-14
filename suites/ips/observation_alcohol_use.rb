module IPS
  class ObservationAlcoholUse < Inferno::TestGroup
    title 'Observation (SH: alcohol use) Tests'
    description 'Verify support for the server capabilities required by the Observation (SH: alcohol use) profile.'
    id :ips_observation_alcohol_use

    test do
      title 'Server returns correct Observation resource from the Observation read interaction'
      description %(
        This test will verify that Observation resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-alcoholuse-uv-ips'

      input :observation_alcohol_use_id
      makes_request :observation_alcohol_use

      run do
        fhir_read(:observation, observation_alcohol_use_id, name: :observation_alcohol_use)

        assert_response_status(200)
        assert_resource_type(:observation)
        assert resource.id == observation_alcohol_use_id,
               "Requested resource with id #{observation_alcohol_use_id}, received resource with id #{resource.id}"
      end
    end

    test do
      title 'Server returns Observation resource that matches the Observation (SH: alcohol use) profile'
      description %(
        This test will validate that the Observation resource returned from the server matches the Observation (SH: alcohol use) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-alcoholuse-uv-ips'
      uses_request :observation_alcohol_use

      run do
        assert_valid_resource(profile_url: 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-alcoholuse-uv-ips')
      end
    end
  end
end
