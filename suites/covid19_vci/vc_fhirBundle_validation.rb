module Covid19VCI
  class VCBundleValidation < Inferno::Test
    title 'Health Card payload fhirBundle resource matches the Allowable Data (SHC) profiles'
    input :fhir_bundle

    id :vc_bundle_validation

    run do
      if fhir_bundle.is_a?(Hash)
        bundle = FHIR::Bundle.new(fhir_bundle)
      else
        bundle = FHIR::Bundle.new(JSON.parse(fhir_bundle)) 
      end
      
      assert bundle.entry.any? { |r| r.resource.is_a?(FHIR::Immunization) } || bundle.entry.any? { |r| r.resource.is_a?(FHIR::Observation) }, 
        "Bundle must have either Immunization entries or Observation entries"

      if bundle.entry.any? { |r| r.resource.is_a?(FHIR::Immunization) }
        assert_valid_resource(resource: bundle, profile_url: 'http://hl7.org/fhir/uv/smarthealthcards-vaccination/StructureDefinition/vaccination-credential-bundle')

        warning do
          assert_valid_resource(resource: bundle, profile_url: 'http://hl7.org/fhir/uv/smarthealthcards-vaccination/StructureDefinition/vaccination-credential-bundle-dm')
        end
      end

      if bundle.entry.any? { |r| r.resource.is_a?(FHIR::Observation) }
        assert_valid_resource(resource: bundle, profile_url: 'http://hl7.org/fhir/uv/smarthealthcards-vaccination/StructureDefinition/covid19-laboratory-bundle')

        warning do
          assert_valid_resource(resource: bundle, profile_url: 'http://hl7.org/fhir/uv/smarthealthcards-vaccination/StructureDefinition/covid19-laboratory-bundle-dm')
        end
      end
    end
  end
end
