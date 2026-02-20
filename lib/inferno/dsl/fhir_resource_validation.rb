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

        def initialize(name = nil, test_suite_id = nil, requirements = nil, &)
          @name = name
          @test_suite_id = test_suite_id
          instance_eval(&)
          @requirements = requirements
        end

        def validator_session_repo
          @validator_session_repo ||= Inferno::Repositories::ValidatorSessions.new
        end

        # Set the url of the validator service
        #
        # @param validator_url [String]
        def url(validator_url = nil)
          @url = validator_url if validator_url
          @url ||= ENV.fetch('FHIR_RESOURCE_VALIDATOR_URL')
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

        # Used internally by perform_additional_validation
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

        # Validate a FHIR resource and determine if it's valid.
        # Adds validation messages to the runnable if add_messages_to_runnable is true.
        #
        # @see Inferno::DSL::FHIRResourceValidation#resource_is_valid?
        # @param resource [FHIR::Model] the resource to validate
        # @param profile_url [String] the profile URL to validate against
        # @param runnable [Object] the runnable context (test/group/suite)
        # @param add_messages_to_runnable [Boolean] whether to add messages to the runnable
        # @param validator_response_details [Object, nil] if not nil, the service will seed the object provided with
        #   the detailed response message from the validator service. Can be used by test kits to perform custom
        #   handling of error messages.
        # @return [Boolean] true if the resource is valid
        def resource_is_valid?(resource, profile_url, runnable, add_messages_to_runnable: true,
                               validator_response_details: nil)
          profile_url ||= FHIR::Definitions.resource_definition(resource.resourceType).url

          # 1. Get raw content from validator
          response = get_raw_validator_content(resource, profile_url, runnable)

          # 2. Convert to validation issues
          issues = get_issues_from_validator_response(response, resource)

          # 3. Add additional validation messages
          issues = join_additional_validation_messages(issues, resource, profile_url)

          # 4. Mark resources as filtered
          mark_issues_for_filtering(issues)

          # 5. Add error messages to runnable
          filtered_issues = issues.reject(&:filtered)
          add_validation_messages_to_runnable(runnable, filtered_issues) if add_messages_to_runnable
          validator_response_details[:issues] = issues if validator_response_details

          # 6. Return validity
          filtered_issues.none? { |issue| issue.severity == 'error' }
        rescue Inferno::Exceptions::ErrorInValidatorException
          raise
        rescue StandardError => e
          runnable.add_message('error', e.message)
          raise Inferno::Exceptions::ErrorInValidatorException,
                'Error occurred in the validator. Review Messages tab or validator service logs for more information.'
        end

        # @private
        # Gets raw content from validator including error handling
        # @param resource [FHIR::Model] the resource to validate
        # @param profile_url [String] the profile URL to validate against
        # @param runnable [Object] the runnable context
        # @return [Faraday::Response] the HTTP response from the validator
        def get_raw_validator_content(resource, profile_url, runnable)
          response = call_validator(resource, profile_url)

          unless response.status == 200
            raise Inferno::Exceptions::ErrorInValidatorException,
                  'Error occurred in the validator. Review Messages tab or validator service logs for more information.'
          end

          response
        rescue StandardError => e
          runnable.add_message('error', e.message)
          Application[:logger].error(e.message)
          raise Inferno::Exceptions::ErrorInValidatorException, validator_error_message(e)
        end

        # @private
        # Adds validation messages to the runnable
        def add_validation_messages_to_runnable(runnable, filtered_issues)
          filtered_issues.each do |issue|
            runnable.add_message(issue.severity, issue.message)
          end
        end

        # Post a resource to the validation service for validating.
        # Returns the raw validator response body.
        #
        # @param resource [FHIR::Model]
        # @param profile_url [String]
        # @return [String] the body of the validation response
        def validate(resource, profile_url)
          call_validator(resource, profile_url).body
        end

        # @private
        # Converts raw validator response into a list of ValidatorIssue objects.
        # Recursively processes slice information.
        #
        # @param response [Faraday::Response] the HTTP response from the validator
        # @param resource [FHIR::Model] the resource being validated
        # @return [Array<ValidatorIssue>] list of validator issues
        def get_issues_from_validator_response(response, resource)
          response_body = remove_invalid_characters(response.body)
          response_hash = JSON.parse(response_body)

          if response_hash['sessionId'].present? && response_hash['sessionId'] != @session_id
            validator_session_repo.save(test_suite_id:, validator_session_id: response_hash['sessionId'],
                                        validator_name: name.to_s, suite_options: requirements)
            @session_id = response_hash['sessionId']
          end

          raw_issues = response_hash.dig('outcomes', 0, 'issues') || []

          raw_issues.map do |raw_issue|
            convert_raw_issue_to_validator_issue(raw_issue, resource)
          end
        end

        # @private
        # Converts a single raw issue hash to a ValidatorIssue object.
        # Recursively processes sliceInfo if present.
        #
        # @param raw_issue [Hash] the raw issue from validator response
        # @param resource [FHIR::Model] the resource being validated
        # @return [ValidatorIssue] the converted validator issue
        def convert_raw_issue_to_validator_issue(raw_issue, resource)
          # Recursively process sliceInfo
          slice_info = []
          if raw_issue['sliceInfo']&.any?
            slice_info = raw_issue['sliceInfo'].map do |slice_issue|
              convert_raw_issue_to_validator_issue(slice_issue, resource)
            end
          end

          ValidatorIssue.new(
            raw_issue: raw_issue,
            resource: resource,
            slice_info: slice_info,
            filtered: false
          )
        end

        # @private
        def call_validator(resource, profile_url)
          request_body = wrap_resource_for_hl7_wrapper(resource, profile_url)
          Faraday.new(
            url,
            request: { timeout: 600 }
          ).post('validate', request_body, content_type: 'application/json')
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

        # @private
        # Removes invalid characters from a string to prepare for JSON parsing
        #
        # @param string [String] the string to clean
        # @return [String] the cleaned string
        def remove_invalid_characters(string)
          string.gsub(/[^[:print:]\r\n]+/, '')
        end

        # @private
        # Joins additional validation messages to the issues list
        #
        # @param issues [Array<ValidatorIssue>] the list of validator issues
        # @param resource [FHIR::Model] the resource being validated
        # @param profile_url [String] the profile URL being validated against
        # @return [Array<ValidatorIssue>] the complete list of issues including additional messages
        def join_additional_validation_messages(issues, resource, profile_url)
          additional_issues = additional_validation_messages(resource, profile_url)
          issues + additional_issues
        end

        # @private
        # Marks validation issues for filtering by setting the filtered flag on issues that should be excluded.
        # Recursively marks issues in slice_info.
        #
        # @param issues [Array<ValidatorIssue>] the list of validator issues
        def mark_issues_for_filtering(issues)
          # Recursively mark all issues for filtering
          filter_individual_messages(issues)

          # Perform conditional filtering based on special cases
          apply_relationship_filters(issues)
        end

        # @private
        # Gets additional validation messages from custom validation blocks.
        # Converts the message hashes to ValidatorIssue objects.
        #
        # @param resource [FHIR::Model] the resource being validated
        # @param profile_url [String] the profile URL being validated against
        # @return [Array<ValidatorIssue>] list of additional validator issues
        def additional_validation_messages(resource, profile_url)
          additional_validations
            .flat_map { |step| step.call(resource, profile_url) }
            .select { |message| message.is_a? Hash }
            .map do |message_hash|
              # Create a synthetic raw_issue for additional validation messages
              synthetic_raw_issue = {
                'level' => message_hash[:type].upcase,
                'location' => 'additional_validation',
                'message' => message_hash[:message]
              }
              ValidatorIssue.new(
                raw_issue: synthetic_raw_issue,
                resource: resource,
                slice_info: [],
                filtered: false
              )
            end
        end

        # @private
        # Recursively filters validation issues by setting the filtered flag.
        # Applies filtering to both the issue itself and all nested slice_info.
        #
        # @param issues [Array<ValidatorIssue>] the issues to filter
        def filter_individual_messages(issues)
          issues.each do |issue|
            # Create a mock message entity to check filtering rules
            mock_message = Entities::Message.new(type: issue.severity, message: issue.message)
            issue.filtered = should_filter_message?(mock_message)

            # Recursively filter slice_info
            filter_individual_messages(issue.slice_info) if issue.slice_info.any?
          end
        end

        # @private
        # Determines if a message should be filtered based on exclusion rules.
        # Applies both the unresolved URL filter and any custom exclude_message filter.
        #
        # @param message [Inferno::Entities::Message] the message to check
        # @return [Boolean] true if the message should be filtered out
        def should_filter_message?(message)
          should_filter = exclude_unresolved_url_message.call(message) ||
                          exclude_message&.call(message)
          should_filter || false
        end

        # @private
        # Filter for excluding unresolved URL validation messages
        #
        # @return [Proc] a proc that checks if a message is an unresolved URL message
        def exclude_unresolved_url_message
          proc do |message|
            message.message.match?(/\A\S+: [^:]+: URL value '.*' does not resolve/) ||
              message.message.match?(/\A\S+: [^:]+: No definition could be found for URL value '.*'/)
          end
        end

        # Performs conditional filtering on issues for special cases.
        # Recursively processes issues and their nested slice_info in depth-first order.
        #
        # @param issues [Array<ValidatorIssue>] the list of validator issues
        def apply_relationship_filters(issues)
          issues.each_with_index do |issue, index|
            next if issue.filtered # Skip if already filtered

            # Apply conditional filters.
            # As more are needed, split with a "next if issue.filtered" pattern and add the new filter.
            filter_contained_resource(issues, issue, index)

            # Recursively process nested slice_info
            apply_relationship_filters(issue.slice_info) if issue.slice_info.any?
          end
        end

        # @private
        # Filters Reference_REF_CantMatchChoice errors for contained resources.
        # If a resource matches at least one profile (all slices filtered), marks the base error as filtered.
        #
        # @param issues [Array<ValidatorIssue>] the complete list of issues
        # @param base_issue [ValidatorIssue] the issue to potentially filter
        # @param base_index [Integer] the index of the base issue in the issues array
        def filter_contained_resource(issues, base_issue, base_index)
          return unless should_filter_contained_resource?(base_issue)

          base_location = base_issue.location
          details_issues = find_following_details_issues(issues, base_index, base_location)

          return if details_issues.empty?

          recursively_process_slice_info_of_details(details_issues)

          return unless at_least_one_valid_detail?(details_issues)

          base_issue.filtered = true
          # Also filter all the Details messages
          details_issues.each { |details_issue| details_issue.filtered = true }
        end

        # @private
        # Checks if a base issue should be processed for contained resource filtering
        def should_filter_contained_resource?(base_issue)
          return false if base_issue.filtered # Skip if already filtered

          message_id = base_issue.raw_issue['messageId']
          return false unless message_id == 'Reference_REF_CantMatchChoice'
          return false unless base_issue.severity == 'error' || base_issue.severity == 'warning'

          true
        end

        # @private
        # Recursively processes slice info within details issues
        def recursively_process_slice_info_of_details(details_issues)
          details_issues.each do |details_issue|
            details_issue.slice_info.each_with_index do |slice_issue, slice_index|
              filter_contained_resource(details_issue.slice_info, slice_issue, slice_index)
            end
          end
        end

        # @private
        # Checks if any profile is valid (all error-level slices are filtered)
        def at_least_one_valid_detail?(details_issues)
          details_issues.any? do |details_issue|
            error_level_slices = details_issue.slice_info.select { |s| s.severity == 'error' }
            error_level_slices.all?(&:filtered)
          end
        end

        # @private
        # Finds consecutive Details messages following a base issue at the same location.
        #
        # @param issues [Array<ValidatorIssue>] the complete list of issues
        # @param start_index [Integer] the index to start searching from
        # @param base_location [String] the location to match
        # @return [Array<ValidatorIssue>] the list of Details issues
        def find_following_details_issues(issues, start_index, base_location)
          details_issues = []
          index = start_index + 1

          while index < issues.length
            issue = issues[index]

            # Check if this is a Details message for the same location
            break unless issue.message.include?('Details for #') && issue.location == base_location

            details_issues << issue
            index += 1
          end

          details_issues
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
      end

      class ValidationContext
        attr_reader :definition

        VALIDATIONCONTEXT_DEFAULTS = {
          sv: '4.0.1',
          doNative: false,
          extensions: ['any'],
          disableDefaultResourceFetcher: true
        }.freeze

        def initialize(definition, &)
          @definition = VALIDATIONCONTEXT_DEFAULTS.merge(definition.deep_symbolize_keys)
          instance_eval(&) if block_given?
        end

        def method_missing(method_name, *args)
          # Interpret any other method as setting a field on validationContext.
          # Follow the same format as `Validator.url` here:
          # only set the value if one is provided.
          # args will be an empty array if no value is provided.
          definition[method_name] = args[0] unless args.empty?

          definition[method_name]
        end

        def respond_to_missing?(_method_name, _include_private = false)
          true
        end
      end

      # ValidatorIssue represents a single validation issue returned from the FHIR validator
      class ValidatorIssue
        attr_accessor :filtered, :raw_issue, :slice_info
        attr_reader :resource

        # Creates a new ValidatorIssue
        # @param raw_issue [Hash] the raw issue hash from the validator response
        # @param resource [FHIR::Model] the resource being validated
        # @param slice_info [Array<ValidatorIssue>] nested slice information as ValidatorIssue objects
        # @param filtered [Boolean] whether this issue has been filtered out
        def initialize(raw_issue:, resource:, slice_info: [], filtered: false)
          @raw_issue = raw_issue
          @resource = resource
          @slice_info = slice_info
          @filtered = filtered
        end

        # Lazily calculated formatted message
        # @return [String] the formatted message for the issue
        def message
          @message ||= format_message
        end

        # Lazily calculated severity level
        # @return [String] 'error', 'warning', or 'info'
        def severity
          @severity ||= calculate_severity
        end

        # Extracted location from the issue
        # @return [String] the location string
        def location
          @location ||= extract_location
        end

        private

        # Formats the issue message with location prefix
        # @return [String] the formatted message
        def format_message
          location_value = extract_location
          details_text = raw_issue['message']

          # Don't add prefix for additional validation messages
          return details_text if location_value == 'additional_validation'

          location_prefix = resource.id ? "#{resource.resourceType}/#{resource.id}" : resource.resourceType
          "#{location_prefix}: #{location_value}: #{details_text}"
        end

        # Converts the validator's severity level to our standard format
        # @return [String] 'error', 'warning', or 'info'
        def calculate_severity
          level = raw_issue['level']
          case level
          when 'ERROR', 'FATAL'
            'error'
          when 'WARNING'
            'warning'
          else
            'info'
          end
        end

        # Extracts the location from the raw issue
        # @return [String] the location string
        def extract_location
          raw_issue['location'] || 'unknown'
        end
      end

      module ClassMethods
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

        # Find a particular profile StructureDefinition and the IG it belongs to.
        # Looks through validators to find the profile by looking through their defined igs.
        #
        # Note: Requires find_validator method which is defined elsewhere in the codebase
        #
        # @param profile_url [String] the profile URL to find
        # @param validator_name [Symbol] the name of the validator to search
        # @return [Array] the IG and profile
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
