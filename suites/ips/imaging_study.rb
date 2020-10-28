module IPS
  class ImagingStudy < Inferno::TestGroup
    title 'Imaging Study (IPS) Tests'
    description 'Verify support for the server capabilities required by the Imaging Study (IPS) profile.'
    id :ips_imaging_study

    input :imaging_study_id

    test do
      title 'Server returns correct ImagingStudy resource from the ImagingStudy read interaction'
      description %(
        This test will verify that ImagingStudy resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/ImagingStudy-uv-ips'
    end

    test do
      title 'Server returns ImagingStudy resource that matches the Imaging Study (IPS) profile'
      description %(
        This test will validate that the ImagingStudy resource returned from the server matches the Imaging Study (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/ImagingStudy-uv-ips'
    end
  end
end
