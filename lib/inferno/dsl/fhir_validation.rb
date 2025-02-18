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
      # @param add_messages_to_runnable [Boolean] whether to add validation messages to runnable or not
      # @return [Boolean] whether the resource is valid
      def resource_is_valid?(
        resource: self.resource, profile_url: nil,
        validator: :default, add_messages_to_runnable: true
      )
        find_validator(validator).resource_is_valid?(resource, profile_url, self, add_messages_to_runnable:)
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
          @url ||= default_validator_url
          @url
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
        def resource_is_valid?(resource, profile_url, runnable, add_messages_to_runnable: true) # rubocop:disable Metrics/CyclomaticComplexity
          profile_url ||= FHIR::Definitions.resource_definition(resource.resourceType).url

          begin
            response = call_validator(resource, profile_url)
          rescue StandardError => e
            # This could be a complete failure to connect (validator isn't running)
            # or a timeout (validator took too long to respond).
            runnable.add_message('error', e.message)
            raise Inferno::Exceptions::ErrorInValidatorException, "Unable to connect to validator at #{url}."
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
          Faraday.new(
            url,
            params: { profile: profile_url }
          ).post('validate', resource.source_contents)
        end

        # @private
        def remove_invalid_characters(string)
          string.gsub(/[^[:print:]\r\n]+/, '')
        end

        # @private
        def operation_outcome_from_validator_response(response, runnable)
          sanitized_body = remove_invalid_characters(response.body)

          FHIR::OperationOutcome.new(JSON.parse(sanitized_body))
        rescue JSON::ParserError
          runnable.add_message('error', "Validator Response: HTTP #{response.status}\n#{sanitized_body}")
          raise Inferno::Exceptions::ErrorInValidatorException,
                'Validator response was an unexpected format. ' \
                'Review Messages tab or validator service logs for more information.'
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
        def validator(name = :default, required_suite_options: nil, &)
          current_validators = fhir_validators[name] || []

          new_validator = Inferno::DSL::FHIRValidation::Validator.new(required_suite_options, &)

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
