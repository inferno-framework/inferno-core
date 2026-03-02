# frozen_string_literal: true

module DevValidatorSuite
  class ValidatorSuite < Inferno::TestSuite
    title 'Validator Suite'
    id :dev_validator
    description 'Inferno Core Developer Suite that makes calls to the HL7 Validator.'

    input :is_spec_test,
          title: 'Spec Test Mode',
          description: 'Internal flag used only by spec tests to skip certain test groups. ' \
                       'Do NOT set this when running the suite normally.',
          type: 'checkbox',
          optional: true

    input :coverage_json,
          title: 'Coverage Resource JSON',
          description: 'JSON content of a Coverage resource with contained resources for validation testing.',
          type: 'textarea',
          locked: true,
          optional: true,
          # rubocop:disable Layout/LineLength
          default: '{"resourceType":"Bundle","type":"collection","entry":[{"fullUrl":"Coverage/id-1.1.8386.BB.1","resource":{"resourceType":"Coverage","id":"id-1.1.8386.BB.1","contained":[{"resourceType":"RelatedPerson","id":"1","patient":{"reference":"Patient/85"},"name":[{"text":"HOLBERG HTI-1","family":"HOLBERG","given":["HTI-1"]}],"gender":"female","birthDate":"2020-04-01","address":[{"line":["PO BOX 1233"],"city":"MOBILE","state":"AL","postalCode":"36695"}]},{"resourceType":"Organization","id":"2","identifier":[{"use":"official","type":{"coding":[{"system":"http://terminology.hl7.org/CodeSystem/v2-0203","code":"TAX"}]},"system":"urn:oid:2.16.840.1.113883.4.4","value":"460391067"},{"use":"official","type":{"coding":[{"system":"http://hl7.org/fhir/us/carin-bb/CodeSystem/C4BBIdentifierType","code":"payerid"}]},"value":"00350"},{"system":"http://cpsi.com/identifiers/organization/financial-class","value":"BB"}],"active":true,"name":"BLUECROSSBOFCALA-O/P-LONGNAMETEST","telecom":[{"system":"phone","value":"2055544321"}],"address":[{"line":["123 TEST ST"],"state":"AL","postalCode":"12345678","country":"US"}]}],"identifier":[{"type":{"coding":[{"system":"http://terminology.hl7.org/CodeSystem/v2-0203","code":"MB","display":"Member Number"}]},"system":"http://trubridge.com/identifiers/coverage/member-number","value":"1234567"}],"status":"active","type":{"coding":[{"system":"https://nahdo.org/sopt","code":"3223","display":"Children of Women Vietnam Veterans (CWVV)"},{"system":"http://terminology.hl7.org/CodeSystem/v3-ActCode","code":"HIP","display":"health insurance plan policy"}],"text":"Children of Women Vietnam Veterans (CWVV)"},"subscriber":{"reference":"#1"},"subscriberId":"123456702","beneficiary":{"reference":"Patient/85"},"relationship":{"coding":[{"system":"http://terminology.hl7.org/CodeSystem/subscriber-relationship","code":"self","display":"self"},{"system":"http://terminology.hl7.org/CodeSystem/v3-RoleCode","code":"NIENE","display":"niece/nephew"},{"system":"http://cpsi.com/CodeSystem/subscriber-relationship","code":"18","display":"self"}],"text":"self"},"payor":[{"reference":"#2"}],"class":[{"type":{"coding":[{"system":"http://terminology.hl7.org/CodeSystem/coverage-class","code":"group","display":"Group"}]},"value":"Grpnumber","name":"Grpname"}],"order":1}}]}'
    # rubocop:enable Layout/LineLength

    fhir_resource_validator do
      url ENV.fetch('FHIR_RESOURCE_VALIDATOR_URL', 'http://localhost/hl7validatorapi')
      igs 'hl7.fhir.us.core#6.1.0'
    end

    group do
      title 'Patient Test Group'
      id :patient_group

      input :url,
            title: 'FHIR Server Base Url'

      input :access_token,
            title: 'Bearer/Access Token',
            optional: true

      input :patient_id,
            title: 'Patient ID'

      fhir_client do
        url :url
        bearer_token :access_token
      end

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

    group do
      title 'Contained Resource Test Group'
      id :contained_resource_group
      optional

      test do
        title 'Coverage Resource with Contained Resources Test'
        id :coverage_contained_resources_test

        input :coverage_json,
              :is_spec_test

        run do
          omit_if is_spec_test.present?, 'Skipping contained resource tests in spec test mode'
          omit_if coverage_json.blank?, 'Coverage JSON input is not provided'

          # Parse the JSON content
          bundle = FHIR.from_contents(coverage_json)

          # Extract the Coverage resource from the Bundle
          assert_resource_type(:bundle, resource: bundle)
          assert bundle.entry.length.positive?, 'Bundle must contain at least one entry'

          coverage_resource = bundle.entry.first.resource

          assert_resource_type(:coverage, resource: coverage_resource)

          # Validate the Coverage resource against US Core v6.1.0 profile
          assert_valid_resource(
            resource: coverage_resource,
            profile_url: 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-coverage|6.1.0'
          )
        end
      end

      test do
        title 'Coverage Resource Validator Response Details Test'
        id :coverage_validator_response_details_test
        description %(
          This test validates the validator_response_details functionality by:
          1. Retrieving detailed validation issues from the validator service
          2. Confirming that Reference_REF_CantMatchChoice errors are present in the raw response
          3. Downgrading these errors to warnings (as they may be acceptable for contained resources)
          4. Filtering out all other validation messages
          5. Expected output: A passing test with a single warning about contained resource reference matching
        )

        input :coverage_json,
              :is_spec_test

        run do
          omit_if is_spec_test.present?, 'Skipping contained resource tests in spec test mode'
          omit_if coverage_json.blank?, 'Coverage JSON input is not provided'

          # Parse the JSON content
          bundle = FHIR.from_contents(coverage_json)

          # Extract the Coverage resource from the Bundle
          coverage_resource = bundle.entry.first.resource

          # Initialize validator_response_details to capture validation issues
          validator_response_details = []

          profile_url = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-coverage|6.1.0'

          # Call resource_is_valid? with validator_response_details
          is_valid = resource_is_valid?(
            resource: coverage_resource,
            profile_url: profile_url,
            add_messages_to_runnable: false,
            validator_response_details: validator_response_details
          )

          # Verify validator_response_details was populated
          assert is_valid, 'Resource should be valid after filtering'
          assert validator_response_details.present?, 'validator_response_details should not be empty'

          # Find Reference_REF_CantMatchChoice errors (regardless of filtered status)
          ref_cant_match_issues = validator_response_details.select do |issue|
            issue.raw_issue['messageId'] == 'Reference_REF_CantMatchChoice'
          end

          assert ref_cant_match_issues.any?,
                 'validator_response_details should contain at least one Reference_REF_CantMatchChoice error'

          # Perform custom filtering: downgrade Reference_REF_CantMatchChoice errors to warnings
          ref_cant_match_count = 0
          other_warning_count = 0
          unresolved_url_count = 0
          validator_response_details.each do |issue|
            # Check if this is an unresolved URL error (these are normally filtered by Inferno)
            is_unresolved_url = issue.message.match?(/URL value '.*' does not resolve/) ||
                                issue.message.match?(/No definition could be found for URL value '.*'/)

            if issue.raw_issue['messageId'] == 'Reference_REF_CantMatchChoice'
              issue.raw_issue['level'] = 'WARNING'
              # Clear the memoized severity so it recalculates
              issue.instance_variable_set(:@severity, nil)
              ref_cant_match_count += 1
            elsif is_unresolved_url && issue.severity == 'error'
              # Downgrade unresolved URL errors to info (matching Inferno's built-in filtering)
              issue.raw_issue['level'] = 'INFORMATION'
              issue.instance_variable_set(:@severity, nil)
              unresolved_url_count += 1
            elsif issue.severity == 'warning'
              # Downgrade all other warnings to info
              issue.raw_issue['level'] = 'INFORMATION'
              issue.instance_variable_set(:@severity, nil)
              other_warning_count += 1
            end
          end

          # Assert there are no remaining errors
          remaining_errors = validator_response_details.select { |issue| issue.severity == 'error' }
          assert remaining_errors.empty?,
                 "Expected no errors after downgrading, but found: #{remaining_errors.map(&:message).join('; ')}"

          # Add messages for anything that is not info level
          validator_response_details.each do |issue|
            next if issue.severity == 'info'

            add_message(issue.severity, issue.message)
          end

          info_msg = "Successfully processed #{ref_cant_match_count} Reference_REF_CantMatchChoice error(s) " \
                     'and downgraded to warning(s)'
          info_msg += ", suppressed #{other_warning_count} other warning(s)" if other_warning_count.positive?
          if unresolved_url_count.positive?
            info_msg += ", and filtered out #{unresolved_url_count} unresolved URL error(s)"
          end
          info_msg += '.'
          info info_msg
        end
      end
    end
  end
end
