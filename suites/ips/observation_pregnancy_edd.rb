module IPS
  class ObservationPregnancyEDD < Inferno::TestGroup
    title 'Observation (Pregnancy: EDD) Tests'
    description 'Verify support for the server capabilities required by the Observation (Pregnancy: EDD) profile.'
    id :ips_observation_pregnancy_edd

    test do
      title 'Server returns correct Observation resource from the Observation read interaction'
      description %(
        This test will verify that Observation resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-pregnancy-edd-uv-ips'

      input :observation_pregnancy_edd_id
      makes_request :observation_pregnancy_edd

      run do
        fhir_read(:observation, observation_pregnancy_edd_id, name: :observation_pregnancy_edd)

        assert_response_status(200)
        assert_resource_type(:observation)
        assert resource.id == observation_pregnancy_edd_id,
               "Requested resource with id #{observation_pregnancy_edd_id}, received resource with id #{resource.id}"
      end
    end

    test do
      title 'Server returns Observation resource that matches the Observation (Pregnancy: EDD) profile'
      description %(
        This test will validate that the Observation resource returned from the server matches the Observation (Pregnancy: EDD) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-pregnancy-edd-uv-ips'
      uses_request :observation_pregnancy_edd

      run do
        assert_valid_resource(profile_url: 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-pregnancy-edd-uv-ips')
      end
    end
  end
end
