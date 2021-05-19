module IPS
  class DocumentOperation < Inferno::TestGroup
    title 'Document Operation Tests'
    description 'Verify support for the $document operation required by the Specimen (IPS) profile.'
    id :ips_document_operation

    test do
      title 'IPS Server declares support for $document operation in CapabilityStatement'
      description %(
        The IPS Server SHALL declare support for Composition/[id]/$document operation in its server CapabilityStatement
      )
      # link 'http://build.fhir.org/composition-operation-document.html'

      run do
        fhir_get_capability_statement
        assert_response_status(200)
        assert_resource_type(:capability_statement)

        operations = resource.rest&.flat_map do |rest|
          rest.resource
            &.select { |r| r.type == 'Composition' && r.respond_to?(:operation) }
            &.flat_map(&:operation)
        end&.compact

        operation_defined = operations.any? do |operation|
          operation.definition == 'http://hl7.org/fhir/OperationDefinition/Composition-document' ||
            ['document', 'composition-document'].include?(operation.name.downcase)
        end

        assert operation_defined, 'Server CapabilityStatement did not declare support for $document operation in Composition resource.'
      end
    end

    test do
      title 'Server returns a fully bundled document from a Composition resource'
      description %(
        This test will perform the $document operation on the chosen composition resource with the persist option on.
        It will verify that all referenced resources in the composition are in the document bundle and that we are able to retrieve the bundle after it's generated.
      )
      # link 'https://www.hl7.org/fhir/composition-operation-document.html'

      input :composition_id
      makes_request :document_operation

      run do
        fhir_read(:composition, composition_id)

        assert_response_status(200)
        assert_resource_type(:composition)
        assert resource.id == composition_id,
               "Requested resource with id #{composition_id}, received resource with id #{resource.id}"

        warning do
          assert_valid_resource(profile_url: 'http://hl7.org/fhir/uv/ips/StructureDefinition/Composition-uv-ips')
        end

        composition = resource
        references_in_composition = []
        walk_resource(composition) do |value, meta, _path|
          next if meta['type'] != 'Reference'
          next if value.reference.blank?

          references_in_composition << value
        end

        fhir_operation("Composition/#{composition.id}/$document?persist=true", name: :document_operation)
        assert_response_status(200)
        assert_resource_type(:bundle)

        bundled_resources = resource.entry.map(&:resource)
        missing_resources =
          references_in_composition
            .select(&:relative?)
            .select do |reference|
              resource_class = reference.resource_class
              resource_id = reference.reference.split('/').last
              bundled_resources.none? do |resource|
                resource.instance_of?(resource_class) && resource.id == resource_id
              end
            end

        assert missing_resources.empty?,
               'The following resources were missing in the response from the document ' \
               "operation: #{missing_resources.map(&:reference).join(',')}"
      end
    end

    test do
      title 'IPS Server returns Bundle resource for Composition/id/$document operation'
      description %(
        IPS Server return valid IPS Bundle resource as successful result of $document operation

        POST [base]/Composition/id/$document
      )
      # link 'https://www.hl7.org/fhir/composition-operation-document.html'
      uses_request :document_operation

      run do
        skip_if !resource.is_a?(FHIR::Bundle), 'No Bundle returned from document operation'

        assert_valid_resource(profile_url: 'http://hl7.org/fhir/uv/ips/StructureDefinition/Bundle-uv-ips')
      end
    end

    test do
      title 'IPS Server returns Bundle resource containing valid IPS Composition entry'
      description %(
        IPS Server return valid IPS Composition resource in the Bundle as first entry
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition-Composition-uv-ips.html'
      uses_request :document_operation

      run do
        skip_if !resource.is_a?(FHIR::Bundle), 'No Bundle returned from document operation'

        assert resource.entry.length.positive?, 'Bundle has no entries'

        entry = resource.entry.first

        assert entry.resource.is_a?(FHIR::Composition), 'The first entry in the Bundle is not a Composition'
        assert_valid_resource(resource: entry, profile_url: 'http://hl7.org/fhir/uv/ips/StructureDefinition/Composition-uv-ips')
      end
    end

    test do
      title 'IPS Server returns Bundle resource containing valid IPS MedicationStatement entry'
      description %(
        IPS Server return valid IPS MedicationStatement resource in the Bundle as first entry
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition-MedicationStatement-uv-ips.html'
      uses_request :document_operation

      run do
        skip_if !resource.is_a?(FHIR::Bundle), 'No Bundle returned from document operation'

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
      uses_request :document_operation

      run do
        skip_if !resource.is_a?(FHIR::Bundle), 'No Bundle returned from document operation'

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
      uses_request :document_operation

      run do
        skip_if !resource.is_a?(FHIR::Bundle), 'No Bundle returned from document operation'

        resources_present = resource.entry.any? { |r| r.resource.is_a?(FHIR::Condition) }

        assert resources_present, 'Bundle does not contain any Condition resources'

        assert_valid_bundle_entries(
          resource_types: {
            condition: 'http://hl7.org/fhir/uv/ips/StructureDefinition/Condition-uv-ips'
          }
        )
      end
    end
  end
end
