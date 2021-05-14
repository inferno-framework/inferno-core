module IPS
  class Composition < Inferno::TestGroup
    title 'Composition (IPS) Tests'
    description 'Verify support for the server capabilities required by the Composition (IPS) profile.'
    id :ips_composition

    test do
      title 'Server returns correct Composition resource from the Composition read interaction'
      description %(
        This test will verify that Composition resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Composition-uv-ips'

      input :composition_id
      makes_request :composition

      run do
        fhir_read(:composition, composition_id, name: :composition)

        assert_response_status(200)
        assert_resource_type(:composition)
        assert resource.id == composition_id,
               "Requested resource with id #{composition_id}, received resource with id #{resource.id}"
      end
    end

    test do
      title 'Server returns Composition resource that matches the Composition (IPS) profile'
      description %(
        This test will validate that the Composition resource returned from the server matches the Composition (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Composition-uv-ips'
      uses_request :composition

      run do
        assert_valid_resource(profile_url: 'http://hl7.org/fhir/uv/ips/StructureDefinition/Composition-uv-ips')
      end
    end

    test do
      title 'Server returns a fully bundled document from a Composition resource'
      description %(
        This test will perform the $document operation on the chosen composition resource with the persist option on.
        It will verify that all referenced resources in the composition are in the document bundle and that we are able to retrieve the bundle after it's generated.
      )
      # link 'https://www.hl7.org/fhir/composition-operation-document.html'
      uses_request :composition

      run do
        skip_if resource.blank?, 'No resource found from Read test'
        composition = resource
        references_in_composition = []
        walk_resource(composition) do |value, meta, _path|
          next if meta['type'] != 'Reference'
          next if value.reference.blank?

          references_in_composition << value
        end

        fhir_client.get("Composition/#{resource.id}/$document?persist=true")
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
               'The following resources were missing in the response from the document' \
               "operation: #{missing_resources.map(&:to_s).join(',')}"
      end
    end
  end
end
