module IPS
  class MedicationStatement < Inferno::TestGroup
    title 'Medication Statement (IPS) Tests'
    description 'Verify support for the server capabilities required by the Medication Statement (IPS) profile.'
    id :ips_medication_statement

    input :medication_statement_id

    test do
      title 'Server returns correct MedicationStatement resource from the MedicationStatement read interaction'
      description %(
        This test will verify that MedicationStatement resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/MedicationStatement-uv-ips'
    end

    test do
      title 'Server returns MedicationStatement resource that matches the Medication Statement (IPS) profile'
      description %(
        This test will validate that the MedicationStatement resource returned from the server matches the Medication Statement (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/MedicationStatement-uv-ips'
    end
  end
end
