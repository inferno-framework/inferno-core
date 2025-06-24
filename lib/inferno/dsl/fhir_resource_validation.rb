require_relative '../ext/fhir_models'
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

          outcome = operation_outcome_from_validator_response(response, runnable)

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
          proc { |message| message.message.match?(/\A\S+: [^:]+: URL value '.*' does not resolve/) }
        end

        # @private
        def filter_messages(message_hashes)
          message_hashes.reject! { |message| exclude_unresolved_url_message.call(Entities::Message.new(message)) }
          message_hashes.reject! { |message| exclude_message.call(Entities::Message.new(message)) } if exclude_message
        end

        # @private
        def message_hashes_from_outcome(outcome, resource, profile_url)
          message_hashes = outcome.issue&.map { |issue| message_hash_from_issue(issue, resource) } || []

          message_hashes.concat(additional_validation_messages(resource, profile_url))

          filter_messages(message_hashes)

          message_hashes
        end

        # @private
        def message_hash_from_issue(issue, resource)
          {
            type: issue_severity(issue),
            message: issue_message(issue, resource)
          }
        end

        # @private
        def issue_severity(issue)
          case issue.severity
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
          location = if issue.respond_to?(:expression)
                       issue.expression&.join(', ')
                     else
                       issue.location&.join(', ')
                     end

          location_prefix = resource.id ? "#{resource.resourceType}/#{resource.id}" : resource.resourceType

          "#{location_prefix}: #{location}: #{issue&.details&.text}"
        end

        # @private
        def wrap_resource_for_hl7_wrapper(resource, profile_url)
          validator_session_id =
            validator_session_repo.find_validator_session_id(test_suite_id,
                                                             name.to_s, requirements)

          @session_id = validator_session_id if validator_session_id

          wrapped_resource = {
            validationContext: {
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
        def operation_outcome_from_hl7_wrapped_response(response_hash)
          # This is a workaround for some test kits which for legacy reasons
          # call this method directly with a String instead of a Hash.
          # See FI-3178.
          response_hash = JSON.parse(remove_invalid_characters(response_hash)) if response_hash.is_a? String

          if response_hash['sessionId'] && response_hash['sessionId'] != @session_id
            validator_session_repo.save(test_suite_id:, validator_session_id: response_hash['sessionId'],
                                        validator_name: name.to_s, suite_options: requirements)
            @session_id = response_hash['sessionId']
          end

          # assume for now that one resource -> one request
          issues = (response_hash.dig('outcomes', 0, 'issues') || []).map do |i|
            { severity: i['level'].downcase, expression: i['location'], details: { text: i['message'] } }
          end
          # this is circuitous, ideally we would map this response directly to message_hashes
          FHIR::OperationOutcome.new(issue: issues)
        end

        # @private
        def remove_invalid_characters(string)
          string.gsub(/[^[:print:]\r\n]+/, '')
        end

        # @private
        def operation_outcome_from_validator_response(response, runnable)
          sanitized_body = remove_invalid_characters(response.body)

          operation_outcome_from_hl7_wrapped_response(JSON.parse(sanitized_body))
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
