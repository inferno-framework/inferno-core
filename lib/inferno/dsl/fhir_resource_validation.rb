require_relative '../ext/fhir_models'
require_relative '../feature'
module Inferno
  module DSL
    # This module contains the methods needed to configure a validator to
    # perform validation of FHIR resources. The actual validation is performed
    # by an external FHIR validation service. Tests will typically rely on
    # `assert_valid_resource` for validation rather than directly calling
    # methods on a validator.
    #
    # @example
    #
    #   fhir_resource_validator do
    #     url 'http://example.com/validator'
    #     exclude_message { |message| message.type == 'info' }
    #     perform_additional_validation do |resource, profile_url|
    #       if something_is_wrong
    #         { type: 'error', message: 'something is wrong' }
    #       else
    #         { type: 'info', message: 'everything is ok' }
    #       end
    #     end
    #     validation_context do
    #       noExtensibleBindingMessages true
    #       allowExampleUrls true
    #       txServer nil
    #     end
    #   end
    module FHIRResourceValidation
      def self.included(klass)
        klass.extend ClassMethods
      end

      # Find a particular profile StructureDefinition and the IG it belongs to.
      # Looks through a runnable's parents up to the suite to find a validator with a particular name,
      # then finds the profile by looking through its defined igs.
      def find_ig_and_profile(profile_url, validator_name)
        self.class.find_ig_and_profile(profile_url, validator_name)
      end

      class Validator
        attr_reader :requirements
        attr_accessor :session_id, :name, :test_suite_id

        # @private
        def initialize(name = nil, test_suite_id = nil, requirements = nil, &)
          @name = name
          @test_suite_id = test_suite_id
          instance_eval(&)
          @requirements = requirements
        end

        # @private
        def default_validator_url
          ENV.fetch('FHIR_RESOURCE_VALIDATOR_URL')
        end

        def validator_session_repo
          @validator_session_repo ||= Inferno::Repositories::ValidatorSessions.new
        end

        # Set the url of the validator service
        #
        # @param validator_url [String]
        def url(validator_url = nil)
          @url = validator_url if validator_url
          @url ||= default_validator_url
          @url
        end

        # Set the IGs that the validator will need to load
        # @example
        #   igs "hl7.fhir.us.core#4.0.0"
        # @example
        #   igs("hl7.fhir.us.core#3.1.1", "hl7.fhir.us.core#6.0.0")
        # @param validator_igs [Array<String>]
        def igs(*validator_igs)
          validation_context(igs: validator_igs) if validator_igs.any?

          validation_context.igs
        end

        # Set the validationContext used as part of each validation request.
        # Fields may be passed as either a Hash or block.
        # Note that all fields included here will be sent directly in requests,
        # there is no check that the fields are correct.
        #
        # @example
        #   # Passing fields in a block
        #   fhir_resource_validator do
        #     url 'http://example.com/validator'
        #     validation_context do
        #       noExtensibleBindingMessages true
        #       allowExampleUrls true
        #       txServer nil
        #     end
        #   end
        #
        # @example
        #   # Passing fields in a Hash
        #   fhir_resource_validator do
        #     url 'http://example.org/validator'
        #     validation_context({
        #       noExtensibleBindingMessages: true,
        #       allowExampleUrls: true,
        #       txServer: nil
        #     })
        #   end
        #
        # @param definition [Hash] raw fields to set, optional
        def validation_context(definition = nil, &)
          if @validation_context
            if definition
              @validation_context.definition.merge!(definition.deep_symbolize_keys)
            elsif block_given?
              @validation_context.instance_eval(&)
            end
          else
            @validation_context = ValidationContext.new(definition || {}, &)
          end
          @validation_context
        end

        alias cli_context validation_context

        # @private
        def additional_validations
          @additional_validations ||= []
        end

        # Perform validation steps in addition to FHIR validation.
        #
        # @example
        #   perform_additional_validation do |resource, profile_url|
        #     if something_is_wrong
        #       { type: 'error', message: 'something is wrong' }
        #     else
        #       { type: 'info', message: 'everything is ok' }
        #     end
        #   end
        # @yieldparam resource [FHIR::Model] the resource being validated
        # @yieldparam profile_url [String] the profile the resource is being
        #   validated against
        # @yieldreturn [Array<Hash<Symbol, String>>,Hash<Symbol, String>] The
        #   block should return a Hash or an Array of Hashes if any validation
        #   messages should be added. The Hash must contain two keys: `:type`
        #   and `:message`. `:type` can have a value of `'info'`, `'warning'`,
        #   or `'error'`. A type of `'error'` means the resource is invalid.
        #   `:message` contains the message string itself.
        def perform_additional_validation(&block)
          additional_validations << block
        end

        # @private
        def additional_validation_messages(resource, profile_url)
          additional_validations
            .flat_map { |step| step.call(resource, profile_url) }
            .select { |message| message.is_a? Hash }
        end

        # Filter out unwanted validation messages. Any messages for which the
        # block evalutates to a truthy value will be excluded.
        #
        # @example
        #   validator do
        #     exclude_message { |message| message.type == 'info' }
        #   end
        # @yieldparam message [Inferno::Entities::Message]
        def exclude_message(&block)
          @exclude_message = block if block_given?
          @exclude_message
        end

        # @see Inferno::DSL::FHIRResourceValidation#resource_is_valid?
        def resource_is_valid?(resource, profile_url, runnable, add_messages_to_runnable: true) # rubocop:disable Metrics/CyclomaticComplexity
          profile_url ||= FHIR::Definitions.resource_definition(resource.resourceType).url

          begin
            response = call_validator(resource, profile_url)
          rescue StandardError => e
            runnable.add_message('error', e.message)
            Application[:logger].error(e.message)

            raise Inferno::Exceptions::ErrorInValidatorException, validator_error_message(e)
          end

          outcome = issue_hash_from_validator_response(response, runnable)

          message_hashes = message_hashes_from_outcome(outcome, resource, profile_url)

          if add_messages_to_runnable
            message_hashes
              .each { |message_hash| runnable.add_message(message_hash[:type], message_hash[:message]) }
          end

          unless response.status == 200
            raise Inferno::Exceptions::ErrorInValidatorException,
                  'Error occurred in the validator. Review Messages tab or validator service logs for more information.'
          end

          message_hashes
            .none? { |message_hash| message_hash[:type] == 'error' }
        rescue Inferno::Exceptions::ErrorInValidatorException
          raise
        rescue StandardError => e
          runnable.add_message('error', e.message)
          raise Inferno::Exceptions::ErrorInValidatorException,
                'Error occurred in the validator. Review Messages tab or validator service logs for more information.'
        end

        # @private
        def exclude_unresolved_url_message
          proc do |message|
            message.message.match?(/\A\S+: [^:]+: URL value '.*' does not resolve/) ||
              message.message.match?(/\A\S+: [^:]+: No definition could be found for URL value '.*'/)
          end
        end

        # @private
        def filter_messages(message_hashes)
          message_hashes.reject! { |message| exclude_unresolved_url_message.call(Entities::Message.new(message)) }
          message_hashes.reject! { |message| exclude_message.call(Entities::Message.new(message)) } if exclude_message
        end

        # @private
        def filter_sliced_messages(message_hashes)
          indices_to_remove = []

          message_hashes.each_with_index do |message_hash, index|
            next unless message_hash[:slices]
            next unless message_hash[:type] == 'error' || message_hash[:type] == 'warning'

            remaining_severity = process_slice_info_and_get_remaining_severity(message_hash[:slices])

            # Only remove if all errors were suppressed
            if remaining_severity.nil?
              indices_to_remove << index
              mark_details_for_removal(message_hashes, index, indices_to_remove)
            end
          end

          # Remove indices in reverse order to maintain correct positions
          indices_to_remove.uniq.sort.reverse.each do |index|
            message_hashes.delete_at(index)
          end
        end

        # @private
        def mark_details_for_removal(message_hashes, index, indices_to_remove)
          # Mark all consecutive Details messages following this base message
          # that match the base message's location
          base_location = extract_location_from_message(message_hashes[index][:message])
          j = index + 1
          while j < message_hashes.length
            next_message = message_hashes[j]
            next_location = extract_location_from_message(next_message[:message])

            # Only mark if it's a Details message AND location matches
            break unless next_message[:message].include?('Details for #') && next_location == base_location

            indices_to_remove << j
            j += 1
          end
        end

        # @private
        # Extract location from a formatted message like "Resource/id: location: message"
        def extract_location_from_message(message)
          # Format is "ResourceType/id: location: message" or "ResourceType: location: message"
          parts = message.split(': ', 3)
          parts[1] if parts.length >= 2
        end

        # @private
        def message_hashes_from_outcome(outcome, resource, profile_url)
          message_hashes = outcome.map do |issue|
            message_hash_from_issue(issue, resource)
          end

          message_hashes.concat(additional_validation_messages(resource, profile_url))

          filter_messages(message_hashes)
          filter_sliced_messages(message_hashes)

          message_hashes
        end

        # @private
        def message_hash_from_issue(issue, resource)
          message_hash = {
            type: issue_severity(issue),
            message: issue_message(issue, resource)
          }

          message_hash[:slices] = issue[:slices] if issue[:slices]

          message_hash
        end

        # @private
        def issue_severity(issue)
          severity = issue.is_a?(Hash) ? issue[:severity] : issue.severity
          case severity
          when 'warning'
            'warning'
          when 'information'
            'info'
          else
            'error'
          end
        end

        # @private
        def issue_message(issue, resource)
          location = extract_issue_location(issue)
          location_prefix = resource.id ? "#{resource.resourceType}/#{resource.id}" : resource.resourceType
          details_text = extract_issue_details(issue)

          "#{location_prefix}: #{location}: #{details_text}"
        end

        # @private
        def extract_issue_location(issue)
          if issue.is_a?(Hash)
            expr = issue[:expression]
            expr.is_a?(Array) ? expr.join(', ') : expr
          elsif issue.respond_to?(:expression)
            issue.expression&.join(', ')
          else
            issue.location&.join(', ')
          end
        end

        # @private
        def extract_issue_details(issue)
          issue.is_a?(Hash) ? issue.dig(:details, :text) : issue&.details&.text
        end

        # @private
        def wrap_resource_for_hl7_wrapper(resource, profile_url)
          validator_session_id =
            validator_session_repo.find_validator_session_id(test_suite_id,
                                                             name.to_s, requirements)

          @session_id = validator_session_id if validator_session_id

          # HL7 Validator Core 6.5.19+ renamed `cliContext` to `validationContext`.
          # This allows backward compatibility until the validator-wrapper is updated.
          context_key = Feature.use_validation_context_key? ? :validationContext : :cliContext

          wrapped_resource = {
            context_key => {
              **validation_context.definition,
              profiles: [profile_url]
            },
            filesToValidate: [
              {
                fileName: "#{resource.resourceType}/#{resource.id}.json",
                fileContent: resource.source_contents,
                fileType: 'json'
              }
            ],
            sessionId: @session_id
          }
          wrapped_resource.to_json
        end

        # Post a resource to the validation service for validating.
        #
        # @param resource [FHIR::Model]
        # @param profile_url [String]
        # @return [String] the body of the validation response
        def validate(resource, profile_url)
          call_validator(resource, profile_url).body
        end

        # @private
        def call_validator(resource, profile_url)
          request_body = wrap_resource_for_hl7_wrapper(resource, profile_url)
          Faraday.new(
            url,
            request: { timeout: 600 }
          ).post('validate', request_body, content_type: 'application/json')
        end

        # @private
        def issue_hash_from_hl7_wrapped_response(response_hash)
          # This is a workaround for some test kits which for legacy reasons
          # call this method directly with a String instead of a Hash.
          # See FI-3178.
          response_hash = JSON.parse(remove_invalid_characters(response_hash)) if response_hash.is_a? String

          if response_hash['sessionId'] && response_hash['sessionId'] != @session_id
            validator_session_repo.save(test_suite_id:, validator_session_id: response_hash['sessionId'],
                                        validator_name: name.to_s, suite_options: requirements)
            @session_id = response_hash['sessionId']
          end

          # Preprocess issues using slice validation details, linking slice-related reference errors
          # with their slice info for later filtering.
          raw_issues = process_issues_with_slice_info(response_hash.dig('outcomes', 0, 'issues') || [])
          # Convert raw validator format to issue hash format, including slices
          raw_issues.map do |i|
            issue_hash = { severity: i['level'].downcase, expression: i['location'], details: { text: i['message'] } }
            issue_hash[:slices] = i['slices'] if i['slices']
            issue_hash
          end
        end

        # @private
        # Finds all consecutive Details messages following a Reference error at the given index.
        # Returns an array of Details issues that match the location and have sliceInfo.
        def find_slice_info(issues_array, base_issue, start_index)
          details_issues = []
          j = start_index

          while j < issues_array.length
            next_issue = issues_array[j]
            if next_issue['messageId'] == 'Details_for__matching_against_Profile_' &&
               next_issue['sliceInfo'] &&
               next_issue['location'] == base_issue['location']
              details_issues << next_issue
              j += 1
            else
              break
            end
          end

          details_issues
        end

        # @private
        # Main processing loop that handles the validator response issues.
        # Looks for Reference_REF_CantMatchChoice errors that have slice details
        # and links them together for later filtering. Collects ALL consecutive
        # Details messages (for resources matching multiple profiles) and merges
        # all their sliceInfo arrays into a single slices array.
        def process_issues_with_slice_info(issues_array)
          processed_issues = []
          i = 0

          while i < issues_array.length
            issue = issues_array[i]

            # Check if this is a reference error that may have slice details
            if issue['messageId'] == 'Reference_REF_CantMatchChoice'
              # Collect all consecutive Details messages with matching location
              details_issues = find_slice_info(issues_array, issue, i + 1)

              # If we found Details messages, merge all their sliceInfo into the base error
              if details_issues.any?
                combined_slices = details_issues.flat_map { |details| details['sliceInfo'] }
                issue['slices'] = combined_slices
                processed_issues << issue
                # Keep all the Details issues as well
                processed_issues.concat(details_issues)
                i += (1 + details_issues.length) # Skip past all processed issues
              else
                # No Details found, add as regular issue
                processed_issues << issue
                i += 1
              end
            else
              # Regular issue - add as-is
              processed_issues << issue
              i += 1
            end
          end

          processed_issues
        end

        # @private
        # Recursively processes slice info to determine what severity level remains
        # after applying suppression filters (like exclude_unresolved_url_message).
        # This is the core logic that enables removing URL resolution errors from slices
        # while preserving legitimate structural validation errors.
        def process_slice_info_and_get_remaining_severity(slice_info_array)
          remaining_errors = []
          remaining_warnings = []
          remaining_info = []

          slice_info_array.each do |slice_issue|
            # Skip issues that should be suppressed (URL resolution errors, custom exclusions)
            next if should_suppress_slice_issue?(slice_issue)

            # If this issue has nested sliceInfo, only consider the nested content
            # Otherwise, categorize it by its own severity level
            if slice_issue['sliceInfo']&.any?
              process_nested_slice_info(slice_issue, remaining_errors, remaining_warnings, remaining_info)
            else
              categorize_slice_issue(slice_issue, remaining_errors, remaining_warnings, remaining_info)
            end
          end

          # Return the highest remaining severity level after suppression
          determine_final_severity(remaining_errors, remaining_warnings, remaining_info)
        end

        # @private
        # Determines if a slice issue should be suppressed by applying the same
        # exclusion filters used for top-level issues. Converts the slice issue
        # to the same prefixed format that base-level issues use before checking.
        def should_suppress_slice_issue?(slice_issue)
          mock_message = create_mock_message_for_slice(slice_issue)

          exclude_unresolved_url_message.call(mock_message) ||
            exclude_message&.call(mock_message)
        end

        # @private
        # Creates a mock message object with the same prefix format used by issue_message
        # for base-level issues: "ResourceType/id: location: message"
        def create_mock_message_for_slice(slice_issue)
          message_type = case slice_issue['level']
                         when 'ERROR'
                           'error'
                         when 'WARNING'
                           'warning'
                         else
                           'info'
                         end

          formatted_message = "Resource/id: #{slice_issue['location']}: #{slice_issue['message']}"

          Entities::Message.new({
                                  type: message_type,
                                  message: formatted_message
                                })
        end

        # @private
        def categorize_slice_issue(slice_issue, remaining_errors, remaining_warnings, remaining_info)
          case slice_issue['level']
          when 'ERROR', 'FATAL'
            remaining_errors << slice_issue
          when 'WARNING'
            remaining_warnings << slice_issue
          else
            remaining_info << slice_issue
          end
        end

        # @private
        def process_nested_slice_info(slice_issue, remaining_errors, remaining_warnings, remaining_info)
          return unless slice_issue['sliceInfo']&.any?

          nested_severity = process_slice_info_and_get_remaining_severity(slice_issue['sliceInfo'])

          case nested_severity
          when 'error'
            remaining_errors << slice_issue
          when 'warning'
            remaining_warnings << slice_issue
          when 'info'
            remaining_info << slice_issue
          end
        end

        # @private
        def determine_final_severity(remaining_errors, _remaining_warnings, _remaining_info)
          # Only keep the base-level error if there are still errors in the slices
          # If only warnings/info remain, treat as fully suppressed
          return 'error' if remaining_errors.any?

          nil # All errors suppressed
        end

        # @private
        def remove_invalid_characters(string)
          string.gsub(/[^[:print:]\r\n]+/, '')
        end

        # @private
        def issue_hash_from_validator_response(response, runnable)
          sanitized_body = remove_invalid_characters(response.body)

          issue_hash_from_hl7_wrapped_response(JSON.parse(sanitized_body))
        rescue JSON::ParserError
          runnable.add_message('error', "Validator Response: HTTP #{response.status}\n#{sanitized_body}")
          raise Inferno::Exceptions::ErrorInValidatorException,
                'Validator response was an unexpected format. ' \
                'Review Messages tab or validator service logs for more information.'
        end

        # Add a specific error message for specific network problems to help the user
        #
        # @private
        # @param error [Exception] An error exception that happened during evaluator connection
        # @return [String] A readable error message describing the specific network problem
        def validator_error_message(error)
          case error
          when Faraday::ConnectionFailed
            "Connection failed to validator at #{url}."
          when Faraday::TimeoutError
            "Timeout while connecting to validator at #{url}."
          when Faraday::SSLError
            "SSL error connecting to validator at #{url}."
          when Faraday::ClientError  # these are 400s
            "Client error (4xx) connecting to validator at #{url}."
          when Faraday::ServerError  # these are 500s
            "Server error (5xx) from validator at #{url}."
          else
            "Unable to connect to validator at #{url}."
          end
        end
      end

      # @private
      class ValidationContext
        attr_reader :definition

        VALIDATIONCONTEXT_DEFAULTS = {
          sv: '4.0.1',
          doNative: false,
          extensions: ['any'],
          disableDefaultResourceFetcher: true
        }.freeze

        # @private
        def initialize(definition, &)
          @definition = VALIDATIONCONTEXT_DEFAULTS.merge(definition.deep_symbolize_keys)
          instance_eval(&) if block_given?
        end

        # @private
        def method_missing(method_name, *args)
          # Interpret any other method as setting a field on validationContext.
          # Follow the same format as `Validator.url` here:
          # only set the value if one is provided.
          # args will be an empty array if no value is provided.
          definition[method_name] = args[0] unless args.empty?

          definition[method_name]
        end

        # @private
        def respond_to_missing?(_method_name, _include_private = false)
          true
        end
      end

      module ClassMethods
        # @private
        def fhir_validators
          @fhir_validators ||= {}
        end

        # Define a validator
        # @example
        #   fhir_resource_validator do
        #     url 'http://example.com/validator'
        #     exclude_message { |message| message.type == 'info' }
        #     perform_additional_validation do |resource, profile_url|
        #       if something_is_wrong
        #         { type: 'error', message: 'something is wrong' }
        #       else
        #         { type: 'info', message: 'everything is ok' }
        #       end
        #     end
        #   end
        #
        # @param name [Symbol] the name of the validator, only needed if you are
        #   using multiple validators
        # @param required_suite_options [Hash] suite options that must be
        #   selected in order to use this validator
        def fhir_resource_validator(name = :default, required_suite_options: nil, &)
          current_validators = fhir_validators[name] || []

          new_validator = Inferno::DSL::FHIRResourceValidation::Validator.new(name, id, required_suite_options, &)

          current_validators.reject! { |validator| validator.requirements == required_suite_options }
          current_validators << new_validator

          fhir_validators[name] = current_validators
        end

        # @private
        def find_ig_and_profile(profile_url, validator_name)
          validator = find_validator(validator_name)
          if validator.is_a? Inferno::DSL::FHIRResourceValidation::Validator
            validator.igs.each do |ig_id|
              ig = Inferno::Repositories::IGs.new.find_or_load(ig_id)
              profile = ig.profile_by_url(profile_url)
              return ig, profile if profile
            end
          end

          raise "Unable to find profile #{profile_url} in any IG defined for validator #{validator_name}"
        end
      end
    end
  end
end
