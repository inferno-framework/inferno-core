module IPS
  class ObservationPregnancyOutcome < Inferno::TestGroup
    title 'Observation (Pregnancy: outcome) Tests'
    description 'Verify support for the server capabilities required by the Observation (Pregnancy: outcome) profile.'
    id :ips_observation_pregnancy_outcome

    input :observation_id

    test do
      title 'Server returns correct Observation resource from the Observation read interaction'
      description %(
        This test will verify that Observation resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-pregnancy-outcome-uv-ips'
    end

    test do
      title 'Server returns Observation resource that matches the Observation (Pregnancy: outcome) profile'
      description %(
        This test will validate that the Observation resource returned from the server matches the Observation (Pregnancy: outcome) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-pregnancy-outcome-uv-ips'
    end
  end
end
