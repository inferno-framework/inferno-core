module IPS
  class SummaryOperation < Inferno::TestGroup
    title 'Summary Operation (IPS) Tests'
    description 'Verify support for the $summary operation required by the Specimen (IPS) profile.'
    id :ips_summary_operation

    input :patient_id

    test do
      title 'IPS Server declares support for $summary operation in CapabilityStatement'
      description %(
        The IPS Server SHALL declare support for Patient/[id]/$summary operation in its server CapabilityStatement
      )
      # link 'http://build.fhir.org/ig/HL7/fhir-ips/index.html'

      run do
        fhir_get_capability_statement
        assert_response_status(200)
        assert_resource_type(:capability_statement)

        operations = resource.rest&.flat_map do |rest|
          rest.resource
            &.select { |r| r.type == 'Composition' && r.respond_to?(:operation) }
            &.map(&:operation)
        end&.compact

        operation_defined = operations.any? do |operation|
          operation.definition == 'http://hl7.org/fhir/OperationDefinition/Patient-summary' ||
            ['summary', 'patient-summary'].include?(operation.name.downcase)
        end

        assert operation_defined, 'Server CapabilityStatement did not declare support for $summary operation in Composition resource.'
      end
    end

    test do
      title 'IPS Server returns Bundle resource for Patient/id/$summary operation'
      description %(
        IPS Server return valid IPS Bundle resource as successful result of $summary operation

        POST [base]/Patient/id/$summary
      )
      # link 'http://build.fhir.org/ig/HL7/fhir-ips/index.html'
      input :patient_id
      makes_request :summary_operation

      run do
        fhir_post("Patient/#{@instance.patient_id}/$summary", name: :summary_operation)
        assert_response_status(200)
        assert_resource_type(:bundle)
        assert_valid_resource(profile: 'http://hl7.org/fhir/uv/ips/StructureDefinition/Bundle-uv-ips')
      end
    end

    test do
      title 'IPS Server returns Bundle resource containing valid IPS Composition entry'
      description %(
        IPS Server return valid IPS Composition resource in the Bundle as first entry
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition-Composition-uv-ips.html'
      uses_request :summary_operation

      run do
        skip_if resource.blank?, 'No bundle returned from document operation'

        assert resource.entry.length.positive?, 'Bundle has no entries'

        entry = resource.entry.first

        assert entry.resource.is_a?(FHIR::Composition), 'The first entry in the Bundle is not a Composition'
        assert_valid_resource(resource: entry, profile: 'http://hl7.org/fhir/uv/ips/StructureDefinition/Composition-uv-ips')
      end
    end

    test do
      title 'IPS Server returns Bundle resource containing valid IPS MedicaitonStatement entry'
      description %(
        IPS Server return valid IPS MedicaitonStatement resource in the Bundle as first entry
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition-MedicationStatement-uv-ips.html'
      uses_request :summary_operation

      run do
        skip_if resource.blank?, 'No bundle returned from document operation'

        resources_present = resource.entry.any? { |r| r.resource.is_a?(FHIR::MedicationStatement) }

        assert resources_present, 'Bundle does not contain any MedicationStatement resources'

        assert_valid_bundle_entries(
          resource_types: {
            medication_statement: 'http://hl7.org/fhir/uv/ips/StructureDefinition/MedicationStatement-uv-ips'
          }
        )
      end
    end

    test do
      title 'IPS Server returns Bundle resource containing valid IPS AllergyIntolerance entry'
      description %(
        IPS Server return valid IPS AllergyIntolerance resource in the Bundle as first entry
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition-AllergyIntolerance-uv-ips.html'
      uses_request :summary_operation

      run do
        skip_if resource.blank?, 'No bundle returned from document operation'

        resources_present = resource.entry.any? { |r| r.resource.is_a?(FHIR::AllergyIntolerance) }

        assert resources_present, 'Bundle does not contain any AllergyIntolerance resources'

        assert_valid_bundle_entries(
          resource_types: {
            allergy_intolerance: 'http://hl7.org/fhir/uv/ips/StructureDefinition/AllergyIntolerance-uv-ips'
          }
        )
      end
    end

    test do
      title 'IPS Server returns Bundle resource containing valid IPS Condition entry'
      description %(
        IPS Server return valid IPS Condition resource in the Bundle as first entry
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition-Condition-uv-ips.html'
      uses_request :summary_operation

      run do
        skip_if resource.blank?, 'No bundle returned from document operation'

        resources_present = resource.entry.any? { |r| r.resource.is_a?(FHIR::Condition) }

        assert resources_present, 'Bundle does not contain any Condition resources'

        assert_valid_bundle_entries(
          resource_types: {
            allergy_intolerance: 'http://hl7.org/fhir/uv/ips/StructureDefinition/Condition-uv-ips'
          }
        )
      end
    end
  end
end
