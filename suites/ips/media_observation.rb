module IPS
  class MediaObservation < Inferno::TestGroup
    title 'Media observation (Results: laboratory, media) Tests'
    description 'Verify support for the server capabilities required by the Media observation (Results: laboratory, media) profile.'
    id :ips_media_observation

    input :media_id

    test do
      title 'Server returns correct Media resource from the Media read interaction'
      description %(
        This test will verify that Media resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Media-observation-uv-ips'
    end

    test do
      title 'Server returns Media resource that matches the Media observation (Results: laboratory, media) profile'
      description %(
        This test will validate that the Media resource returned from the server matches the Media observation (Results: laboratory, media) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Media-observation-uv-ips'
    end
  end
end
