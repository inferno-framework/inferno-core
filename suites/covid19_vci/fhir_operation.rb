module Covid19VCI
  class FHIROperation < Inferno::TestGroup
    id 'vci_fhir_operation'
    title 'Download and validate a health card via FHIR $health-cards-issue operation'

    fhir_client do
      url :base_fhir_url
    end

    test do
      title 'Server advertises health card support in its SMART configuration'
      id 'vci-fhir-01'
      input :base_fhir_url

      run do
        get("#{base_fhir_url}/.well-known/smart-configuration")

        assert_response_status(200)
        assert_valid_json(response[:body])

        smart_configuration = JSON.parse(response[:body])

        assert smart_configuration['capabilities']&.include?('health-cards'),
               "SMART configuration does not list support for 'health-cards' capability"
      end
    end

    test do
      title 'Server advertises $health-cards-issue operation support in its CapabilityStatement'
      id 'vci-fhir-02'
      input :base_fhir_url

      run do
        fhir_get_capability_statement

        assert_response_status(200)

        operations = resource.rest&.flat_map do |rest|
          rest.resource
            &.select { |r| r.type == 'Patient' && r.respond_to?(:operation) }
            &.flat_map(&:operation)
        end&.compact

        operation_defined = operations.any? { |operation| operation.name == 'health-cards-issue' }

        assert operation_defined,
               'Server CapabilityStatement did not declare support for $health-cards-issue operation ' \
               'on the Patient resource.'
      end
    end

    test do
      title 'Server returns a health card from the $health-cards-issue operation'
      id 'vci-fhir-03'
      input :base_fhir_url, :patient_id, :optional_bearer_token
      output :credential_strings

      run do
        if optional_bearer_token.present?
          fhir_client.set_bearer_token(optional_bearer_token)
        end
        request_params = FHIR::Parameters.new(
          parameter: [
            {
              name: 'credentialType',
              valueUri: 'https://smarthealth.cards#covid19'
            }
          ]
        )
        fhir_operation("/Patient/#{patient_id}/$health-cards-issue", body: request_params)

        assert_response_status((200..207).to_a)
        assert_resource_type(:parameters)

        hc_parameters = resource.parameter.select { |parameter| parameter.name == 'verifiableCredential' }

        assert hc_parameters.present?, 'No COVID-19 health cards were returned'
        credential_strings = hc_parameters.map(&:value).join(',')

        output credential_strings: credential_strings

        count = hc_parameters.length

        pass "#{count} verifiable #{'credential'.pluralize(count)} received"
      end
    end

    test from: :vc_headers do
      id 'vci-fhir-04'
    end

    test from: :vc_signature_verification do
      id 'vci-fhir-05'
    end

    test from: :vc_payload_verification do
      id 'vci-fhir-06'
    end
  end
end
