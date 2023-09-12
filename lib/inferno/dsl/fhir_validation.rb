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
    #   validator do
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
    module FHIRValidation
      def self.included(klass)
        klass.extend ClassMethods
      end

      # Perform validation, and add validation messages to the runnable
      #
      # @param resource [FHIR::Model]
      # @param profile_url [String]
      # @param validator [Symbol] the name of the validator to use
      # @return [Boolean] whether the resource is valid
      def resource_is_valid?(resource: self.resource, profile_url: nil, validator: :default)
        find_validator(validator).resource_is_valid?(resource, profile_url, self)
      end

      # Find a particular validator. Looks through a runnable's parents up to
      # the suite to find a validator with a particular name
      def find_validator(validator_name)
        self.class.find_validator(validator_name, suite_options)
      end

      class Validator
        attr_reader :requirements

        # @private
        def initialize(requirements = nil, &)
          instance_eval(&)
          @requirements = requirements
        end

        # @private
        def default_validator_url
          ENV.fetch('VALIDATOR_URL')
        end

        # Set the url of the validator service
        #
        # @param validator_url [String]
        def url(validator_url = nil)
          @url = validator_url if validator_url

          @url
        end

        # Set the IGs that the validator will need to load
        # Example: ["hl7.fhir.us.core#4.0.0"]
        # @param igs [Array<String>]
        def igs(validator_igs = nil)
          @igs = validator_igs if validator_igs

          @igs
        end

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

        # @see Inferno::DSL::FHIRValidation#resource_is_valid?
        def resource_is_valid?(resource, profile_url, runnable)
          profile_url ||= FHIR::Definitions.resource_definition(resource.resourceType).url

          outcome, http_status = validate(resource, profile_url, runnable)

          message_hashes = message_hashes_from_outcome(outcome, resource, profile_url)

          message_hashes
            .each { |message_hash| runnable.add_message(message_hash[:type], message_hash[:message]) }

          unless http_status == 200
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
        def filter_messages(message_hashes)
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
          wrapped_resource = {
            cliContext: {
              # TODO: these should be configurable as well
              sv: '4.0.1',
              # displayWarnings: true,  # -display-issues-are-warnings
              # txServer: nil,          # -tx n/a
              igs: @igs || [],
              # NOTE: this profile must be part of a loaded IG,
              # otherwise the response is an HTTP 500 with no content
              profiles: [profile_url]
            },
            filesToValidate: [
              {
                fileName: 'manually_entered_file.json',
                fileContent: resource.to_json,
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
        # @param runnable [Inferno::Entities::Test]
        # @return [[Array(FHIR::OperationOutcome, Number)] the validation response and HTTP status code
        def validate(resource, profile_url, runnable)
          begin
            request_body = wrap_resource_for_hl7_wrapper(resource, profile_url)
            response = Faraday.new(
              url
            ).post('validate', request_body, content_type: 'application/json')
          rescue StandardError => e
            runnable.add_message('error', e.message)
            raise Inferno::Exceptions::ErrorInValidatorException, "Unable to connect to validator at #{url}."
          end
          outcome = operation_outcome_from_validator_response(response, runnable)
          [outcome, response.status]
        end

        # @private
        def operation_outcome_from_hl7_wrapped_response(response)
          res = JSON.parse(response)

          @session_id = res['sessionId']

          # assume for now that one resource -> one request
          issues = res['outcomes'][0]['issues']&.map do |i|
            { severity: i['level'].downcase, expression: i['location'], details: { text: i['message'] } }
          end
          # this is circuitous, ideally we would map this response directly to message_hashes
          FHIR::OperationOutcome.new(issue: issues)
        end

        # @private
        def operation_outcome_from_validator_response(response, runnable)
          if response.body.start_with? '{'
            operation_outcome_from_hl7_wrapped_response(response.body)
          else
            runnable.add_message('error', "Validator Response: HTTP #{response.status}\n#{response.body}")
            raise Inferno::Exceptions::ErrorInValidatorException,
                  'Validator response was an unexpected format. '\
                  'Review Messages tab or validator service logs for more information.'
          end
        end
      end

      module ClassMethods
        # @private
        def fhir_validators
          @fhir_validators ||= {}
        end

        # Define a validator
        # @example
        #   validator do
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
        def validator(name = :default, required_suite_options: nil, &block)
          current_validators = fhir_validators[name] || []

          new_validator = Inferno::DSL::FHIRValidation::Validator.new(required_suite_options, &block)

          current_validators.reject! { |validator| validator.requirements == required_suite_options }
          current_validators << new_validator

          fhir_validators[name] = current_validators
        end

        # Find a particular validator. Looks through a runnable's parents up to
        # the suite to find a validator with a particular name
        def find_validator(validator_name, selected_suite_options = nil)
          validators = fhir_validators[validator_name] ||
                       Array.wrap(parent&.find_validator(validator_name, selected_suite_options))

          validator =
            if selected_suite_options.present?
              validators.find do |possible_validator|
                possible_validator.requirements.nil? || selected_suite_options >= possible_validator.requirements
              end
            else
              validators.first
            end

          raise Exceptions::ValidatorNotFoundException, validator_name if validator.nil?

          validator
        end
      end
    end
  end
end
