module Covid19VCI
  class VCFHIRVerification < Inferno::Test
    title 'Health Card payloads conform to the Vaccination Credential Bundle Profiles'
    input :credential_strings

    id :vc_fhir_verification

    run do
      skip_if credential_strings.blank?, 'No Verifiable Credentials received'

      credential_strings.split(',').each do |credential|
        raw_payload = HealthCards::JWS.from_jws(credential).payload
        assert raw_payload&.length&.positive?, 'No payload found'

        decompressed_payload =
          begin
            Zlib::Inflate.new(-Zlib::MAX_WBITS).inflate(raw_payload)
          rescue Zlib::DataError
            assert false, 'Payload compression error. Unable to inflate payload.'
          end

        assert decompressed_payload.length.positive?, 'Payload compression error. Unable to inflate payload.'

        payload_length = decompressed_payload.length
        health_card = HealthCards::COVIDHealthCard.from_jws(credential)
        health_card_length = health_card.to_json.length

        assert_valid_json decompressed_payload, 'Payload is not valid JSON'

        payload = JSON.parse(decompressed_payload)
        vc = payload['vc']
        assert vc.is_a?(Hash), "Expected 'vc' claim to be a JSON object, but found #{vc.class}"

        subject = vc['credentialSubject']
        assert subject.is_a?(Hash), "Expected 'vc.credentialSubject' to be a JSON object, but found #{subject.class}"

        raw_bundle = subject['fhirBundle']
        assert raw_bundle.is_a?(Hash), "Expected 'vc.fhirBundle' to be a JSON object, but found #{raw_bundle.class}"

        bundle = FHIR::Bundle.new(raw_bundle)

        assert bundle.entry.any? { |r| r.resource.is_a?(FHIR::Immunization) } || bundle.entry.any? { |r| r.resource.is_a?(FHIR::Observation) }, 
        "Bundle must have either Immunization entries or Observation entries"

        if bundle.entry.any? { |r| r.resource.is_a?(FHIR::Immunization) }
          assert_valid_resource(
            resource: bundle, 
            profile_url: 'http://hl7.org/fhir/uv/smarthealthcards-vaccination/StructureDefinition/vaccination-credential-bundle'
          )

          warning do
            assert_valid_resource(
              resource: bundle, 
              profile_url: 'http://hl7.org/fhir/uv/smarthealthcards-vaccination/StructureDefinition/vaccination-credential-bundle-dm'
            )
          end
        end

        if bundle.entry.any? { |r| r.resource.is_a?(FHIR::Observation) }
          assert_valid_resource(
            resource: bundle, 
            profile_url: 'http://hl7.org/fhir/uv/smarthealthcards-vaccination/StructureDefinition/covid19-laboratory-bundle'
          )

          warning do
            assert_valid_resource(
              resource: bundle, 
              profile_url: 'http://hl7.org/fhir/uv/smarthealthcards-vaccination/StructureDefinition/covid19-laboratory-bundle-dm'
            )
          end
        end
      end
    end
  end
end
