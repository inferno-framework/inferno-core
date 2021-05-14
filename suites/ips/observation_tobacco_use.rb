module IPS
  class ObservationTobaccoUse < Inferno::TestGroup
    title 'Observation (SH: tobacco use) Tests'
    description 'Verify support for the server capabilities required by the Observation (SH: tobacco use) profile.'
    id :ips_observation_tobacco_use

    input :observation_tobacco_use_id

    test do
      title 'Server returns correct Observation resource from the Observation read interaction'
      description %(
        This test will verify that Observation resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-tobaccouse-uv-ips'
      makes_request :observation_tobacco_use

      run do
        fhir_read(:observation, observation_tobacco_use_id, name: :observation_tobacco_use)

        assert_response_status(200)
        assert_resource_type(:observation)
        assert resource.id == observation_tobacco_use_id,
               "Requested resource with id #{observation_tobacco_use_id}, received resource with id #{resource.id}"
      end
    end

    test do
      title 'Server returns Observation resource that matches the Observation (SH: tobacco use) profile'
      description %(
        This test will validate that the Observation resource returned from the server matches the Observation (SH: tobacco use) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-tobaccouse-uv-ips'
      uses_request :observation_tobacco_use

      run do
        assert_valid_resource(profile_url: 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-tobaccouse-uv-ips')
      end
    end
  end
end
