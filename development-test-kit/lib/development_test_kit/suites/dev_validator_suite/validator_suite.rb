# frozen_string_literal: true

module DevelopmentTestKit
  class ValidatorSuite < Inferno::TestSuite
    title 'Validator Suite'
    id :dev_validator
    description 'Inferno Core Developer Suite that makes calls to the HL7 Validator.'

    input :url,
          title: 'FHIR Server Base Url'

    input :access_token,
          title: 'Bearer/Access Token',
          optional: true

    fhir_client do
      url :url
      bearer_token :access_token
    end

    fhir_resource_validator do
      url 'http://localhost/hl7validatorapi'
    end

    group do
      title 'Patient Test Group'
      id :patient_group

      input :patient_id,
            title: 'Patient ID'

      test do
        title 'Patient Read Test'
        id :patient_read_test

        makes_request :patient_read

        run do
          fhir_read(:patient, patient_id, name: :patient_read)

          assert_response_status 200
        end
      end

      test do
        title 'Patient Validate Test'
        id :patient_validate_test

        uses_request :patient_read

        run do
          assert_resource_type(:patient)
          assert_valid_resource
        end
      end
    end
  end
end
