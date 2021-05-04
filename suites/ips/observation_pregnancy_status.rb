module IPS
  class ObservationPregnancyStatus < Inferno::TestGroup
    title 'Observation (Pregnancy: status) Tests'
    description 'Verify support for the server capabilities required by the Observation (Pregnancy: status) profile.'
    id :ips_observation_pregnancy_status

    input :observation_id

    test do
      title 'Server returns correct Observation resource from the Observation read interaction'
      description %(
        This test will verify that Observation resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-pregnancy-status-uv-ips'
      makes_request :observation_pregnancy_status

      run do
        fhir_read(:observation, observation_id, name: :observation_pregnancy_status)

        assert_response_status(200)
        assert_resource_type(:observation)
        assert resource.id == observation_id,
               "Requested resource with id #{observation_id}, received resource with id #{resource.id}"
      end
    end

    test do
      title 'Server returns Observation resource that matches the Observation (Pregnancy: status) profile'
      description %(
        This test will validate that the Observation resource returned from the server matches the Observation (Pregnancy: status) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-pregnancy-status-uv-ips'
      uses_request :observation_pregnancy_status

      run do
        assert_valid_resource(profile_url: 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-pregnancy-status-uv-ips')
      end
    end
  end
end
