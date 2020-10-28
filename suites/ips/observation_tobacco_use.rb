module IPS
  class ObservationTobaccoUse < Inferno::TestGroup
    title 'Observation (SH: tobacco use) Tests'
    description 'Verify support for the server capabilities required by the Observation (SH: tobacco use) profile.'
    id :ips_observation_tobacco_use

    input :observation_id

    test do
      title 'Server returns correct Observation resource from the Observation read interaction'
      description %(
        This test will verify that Observation resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-tobaccouse-uv-ips'
    end

    test do
      title 'Server returns Observation resource that matches the Observation (SH: tobacco use) profile'
      description %(
        This test will validate that the Observation resource returned from the server matches the Observation (SH: tobacco use) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Observation-tobaccouse-uv-ips'
    end
  end
end
