module Covid19VCI
  class FHIROperation < Inferno::TestGroup
    id 'vci_fhir_operation'
    title 'Download and validate a health card via FHIR $health-cards-issue operation'

    input :base_fhir_url, :patient_id

    fhir_client do
      url :base_fhir_url
    end

    test do
      title 'Server advertises health card support in its SMART configuration'

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
      title 'Server advertises $health-card-issue operation support in its CapabilityStatement'

      run do
        fhir_get_capability_statement

        assert_response_status(200)

        operations = resource.rest&.flat_map do |rest|
          rest.resource
            &.select { |r| r.type == 'Patient' && r.respond_to?(:operation) }
            &.flat_map(&:operation)
        end&.compact

        operation_defined = operations.any? { |operation| operation.name == 'health-cards-issue' }

        assert operation_defined, 'Server CapabilityStatement did not declare support for $health-cards-issue operation in Composition resource.'
      end
    end

    test do
      title 'Server returns a health card from the $health-card-issue operation'
      output :credential_strings

      run do
        request_params = FHIR::Parameters.new(
          parameter: [
            {
              name: 'credentialType',
              valueUri: 'https://smarthealth.cards#covid19'
            }
          ]
        )
        fhir_operation("/Patient/#{patient_id}/$health-card-issue", request_params)

        assert_response_status((200..207).to_a)
        assert_resource_type(:parameters)

        hc_parameters = resource.parameter.select { |parameter| parameter.name == 'verifiableCredential' }

        assert hc_parameters.present?, 'No COVID-19 health cards were returned'
        credential_strings = hc_paramameters.map(&:value).join(',')

        output credential_strings: credential_strings

        count = hc_parameters.length

        pass "#{count} verifiable #{'credential'.pluralize(count)} were received"
      end
    end
  end
end
