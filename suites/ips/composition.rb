module IPS
  class Composition < Inferno::TestGroup
    title 'Composition (IPS) Tests'
    description 'Verify support for the server capabilities required by the Composition (IPS) profile.'
    id :ips_composition

    input :composition_id

    test do
      title 'Server returns correct Composition resource from the Composition read interaction'
      description %(
        This test will verify that Composition resources can be read from the server.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Composition-uv-ips'
    end

    test do
      title 'Server returns Composition resource that matches the Composition (IPS) profile'
      description %(
        This test will validate that the Composition resource returned from the server matches the Composition (IPS) profile.
      )
      # link 'http://hl7.org/fhir/uv/ips/StructureDefinition/Composition-uv-ips'
    end

    test do
      title 'Server returns a fully bundled document from a Composition resource'
      description %(
        This test will perform the $document operation on the chosen composition resource with the persist option on.
        It will verify that all referenced resources in the composition are in the document bundle and that we are able to retrieve the bundle after it's generated.
      )
      # link 'https://www.hl7.org/fhir/composition-operation-document.html'
    end
  end
end
