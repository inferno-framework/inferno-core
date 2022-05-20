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
        self.class.find_validator(validator_name)
      end

      class Validator
        # @private
        def initialize(&block)
          instance_eval(&block)
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

        # Filter out unwanted validation messages
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

          outcome = FHIR::OperationOutcome.new(JSON.parse(validate(resource, profile_url)))

          message_hashes = outcome.issue&.map { |issue| message_hash_from_issue(issue, resource) } || []

          message_hashes.concat(additional_validation_messages(resource, profile_url))

          filter_messages(message_hashes)

          message_hashes
            .each { |message_hash| runnable.add_message(message_hash[:type], message_hash[:message]) }
            .none? { |message_hash| message_hash[:type] == 'error' }
        end

        # @private
        def filter_messages(message_hashes)
          message_hashes.reject! { |message| exclude_message.call(Entities::Message.new(message)) } if exclude_message
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

          location.prepend("#{resource.resourceType}#{"/#{resource.id.to_s}" if resource.id}/")

          "#{location}: #{issue&.details&.text}"
        end

        # Post a resource to the validation service for validating.
        #
        # @param resource [FHIR::Model]
        # @param profile_url [String]
        # @return [String] the body of the validation response
        def validate(resource, profile_url)
          RestClient.post(
            "#{url}/validate",
            resource.source_contents,
            params: { profile: profile_url }
          ).body
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
        def validator(name = :default, &block)
          fhir_validators[name] = Inferno::DSL::FHIRValidation::Validator.new(&block)
        end

        # Find a particular validator. Looks through a runnable's parents up to
        # the suite to find a validator with a particular name
        def find_validator(validator_name)
          validator = fhir_validators[validator_name] || parent&.find_validator(validator_name)

          raise Exceptions::ValidatorNotFoundException, validator_name if validator.nil?

          validator
        end
      end
    end
  end
end
