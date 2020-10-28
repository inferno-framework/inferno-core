module IPS
  class Patient < Inferno::TestGroup
    title 'Patient (IPS) Tests'
    description 'Verify support for the server capabilities required by the Patient (IPS) profile.'
    id :ips_patient

    input :patient_id

    test do
      title 'Server returns correct Patient resource from the Patient read interaction'
      description %(
        This test will verify that Patient resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Patient-uv-ips'
    end

    test do
      title 'Server returns Patient resource that matches the Patient (IPS) profile'
      description %(
        This test will validate that the Patient resource returned from the server matches the Patient (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Patient-uv-ips'
    end
  end
end
