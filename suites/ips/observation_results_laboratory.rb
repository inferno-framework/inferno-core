module IPS
  class ObservationResultsLaboratory < Inferno::TestGroup
    title 'Observation Results: laboratory (IPS) Tests'
    description 'Verify support for the server capabilities required by the Observation Results: laboratory (IPS) profile.'
    id :ips_observation_results_laboratory

    input :observation_results_laboratory_id

    test do
      title 'Server returns correct Observation resource from the Observation read interaction'
      description %(
        This test will verify that Observation resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-results-laboratory-uv-ips'
      makes_request :observation_lab

      run do
        fhir_read(:observation, observation_results_laboratory_id, name: :observation_lab)

        assert_response_status(200)
        assert_resource_type(:observation)
        assert resource.id == observation_results_laboratory_id,
               "Requested resource with id #{observation_results_laboratory_id}, received resource with id #{resource.id}"
      end
    end

    test do
      title 'Server returns Observation resource that matches the Observation Results: laboratory (IPS) profile'
      description %(
        This test will validate that the Observation resource returned from the server matches the Observation Results: laboratory (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-results-laboratory-uv-ips'
      uses_request :observation_lab

      run do
        assert_valid_resource(profile_url: 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-results-laboratory-uv-ips')
      end
    end
  end
end
