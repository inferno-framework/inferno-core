module IPS
  class ObservationResultsLaboratory < Inferno::TestGroup
    title 'Observation Results: laboratory (IPS) Tests'
    description 'Verify support for the server capabilities required by the Observation Results: laboratory (IPS) profile.'
    id :ips_observation_results_laboratory

    input :observation_id

    test do
      title 'Server returns correct Observation resource from the Observation read interaction'
      description %(
        This test will verify that Observation resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-results-laboratory-uv-ips'
    end

    test do
      title 'Server returns Observation resource that matches the Observation Results: laboratory (IPS) profile'
      description %(
        This test will validate that the Observation resource returned from the server matches the Observation Results: laboratory (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-results-laboratory-uv-ips'
    end
  end
end
