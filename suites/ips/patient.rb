module IPS
  class Patient < Inferno::TestGroup
    title 'Patient (IPS) Tests'
    description 'Verify support for the server capabilities required by the Patient (IPS) profile.'
    id :ips_patient

    test do
      title 'Server returns correct Patient resource from the Patient read interaction'
      description %(
        This test will verify that Patient resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Patient-uv-ips'

      input :patient_id
      makes_request :patient

      run do
        fhir_read(:patient, patient_id, name: :patient)

        assert_response_status(200)
        assert_resource_type(:patient)
        assert resource.id == patient_id,
               "Requested resource with id #{patient_id}, received resource with id #{resource.id}"
      end
    end

    test do
      title 'Server returns Patient resource that matches the Patient (IPS) profile'
      description %(
        This test will validate that the Patient resource returned from the server matches the Patient (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Patient-uv-ips'
      uses_request :patient

      run do
        assert_valid_resource(profile_url: 'http://hl7.org/fhir/uv/ips/StructureDefinition/Patient-uv-ips')
      end
    end
  end
end
