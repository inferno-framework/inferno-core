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

    fhir_resource_validator :default do
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

        run do
          omit_if is_spec_test.present?, 'Skipping contained resource tests in spec test mode'

          # Read the JSON file
          json_file_path = File.join(__dir__, 'fixtures', 'coverage_contained_resource.json')
          json_content = File.read(json_file_path)
          bundle = FHIR.from_contents(json_content)

          # Extract the Coverage resource from the Bundle
          assert bundle.is_a?(FHIR::Bundle), 'Expected a FHIR Bundle'
          assert bundle.entry.length.positive?, 'Bundle must contain at least one entry'

          coverage_resource = bundle.entry.first.resource

          assert coverage_resource.is_a?(FHIR::Coverage), 'Expected a Coverage resource'

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

        run do
          omit_if is_spec_test.present?, 'Skipping contained resource tests in spec test mode'

          # Read the JSON file
          json_file_path = File.join(__dir__, 'fixtures', 'coverage_contained_resource.json')
          json_content = File.read(json_file_path)
          bundle = FHIR.from_contents(json_content)

          # Extract the Coverage resource from the Bundle
          coverage_resource = bundle.entry.first.resource

          # Initialize validator_response_details to capture validation issues
          validator_response_details = {}

          # Get the validator using the instance method
          validator = find_validator(:default)
          profile_url = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-coverage|6.1.0'

          # Call resource_is_valid? with validator_response_details
          is_valid = validator.resource_is_valid?(
            coverage_resource,
            profile_url,
            self,
            add_messages_to_runnable: false,
            validator_response_details: validator_response_details
          )

          # Verify validator_response_details was populated
          assert is_valid, 'Resource should be valid after filtering'
          assert validator_response_details.present?, 'validator_response_details should not be empty'
          assert validator_response_details[:issues].present?, 'validator_response_details should contain issues'

          # Find Reference_REF_CantMatchChoice errors (regardless of filtered status)
          ref_cant_match_issues = validator_response_details[:issues].select do |issue|
            issue.raw_issue['messageId'] == 'Reference_REF_CantMatchChoice'
          end

          assert ref_cant_match_issues.any?,
                 'validator_response_details should contain at least one Reference_REF_CantMatchChoice error'

          # Perform custom filtering: downgrade Reference_REF_CantMatchChoice errors to warnings
          ref_cant_match_count = 0
          other_warning_count = 0
          unresolved_url_count = 0
          validator_response_details[:issues].each do |issue|
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
          remaining_errors = validator_response_details[:issues].select { |issue| issue.severity == 'error' }
          assert remaining_errors.empty?,
                 "Expected no errors after downgrading, but found: #{remaining_errors.map(&:message).join('; ')}"

          # Add messages for anything that is not info level
          validator_response_details[:issues].each do |issue|
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
