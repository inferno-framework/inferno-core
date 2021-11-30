module Inferno
  module DSL
    module FHIRValidation
      def self.included(klass)
        klass.extend ClassMethods
      end

      def resource_is_valid?(resource: self.resource, profile_url: nil, validator: :default)
        find_validator(validator).resource_is_valid?(resource, profile_url, self)
      end

      def find_validator(validator_name)
        self.class.find_validator(validator_name)
      end

      class Validator
        def initialize(&block)
          instance_eval(&block)
        end

        def default_validator_url
          ENV.fetch('VALIDATOR_URL')
        end

        def url(validator_url = nil)
          @url = validator_url if validator_url

          @url
        end

        def additional_validations
          @additional_validations ||= []
        end

        def perform_additional_validation(&block)
          additional_validations << block
        end

        def additional_validation_messages(resource, profile_url)
          additional_validations
            .flat_map { |step| step.call(resource, profile_url) }
            .select { |message| message.is_a? Hash }
        end

        def exclude_message(&block)
          @exclude_message = block if block_given?
          @exclude_message
        end

        def resource_is_valid?(resource, profile_url, runnable)
          profile_url ||= FHIR::Definitions.resource_definition(resource.resourceType).url

          outcome = FHIR::OperationOutcome.new(JSON.parse(validate(resource, profile_url)))

          message_hashes = outcome.issue&.map { |issue| message_hash_from_issue(issue) } || []

          message_hashes.concat(additional_validation_messages(resource, profile_url))

          filter_messages(message_hashes)

          message_hashes
            .each { |message_hash| runnable.add_message(message_hash[:type], message_hash[:message]) }
            .none? { |message_hash| message_hash[:type] == 'error' }
        end

        def filter_messages(message_hashes)
          message_hashes.reject! { |message| exclude_message.call(Entities::Message.new(message)) } if exclude_message
        end

        def message_hash_from_issue(issue)
          {
            type: issue_severity(issue),
            message: issue_message(issue)
          }
        end

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

        def issue_message(issue)
          location = if issue.respond_to?(:expression)
                       issue.expression&.join(', ')
                     else
                       issue.location&.join(', ')
                     end

          "#{location}: #{issue&.details&.text}"
        end

        def validate(resource, profile_url)
          RestClient.post(
            "#{url}/validate",
            resource.to_json,
            params: { profile: profile_url }
          ).body
        end
      end

      module ClassMethods
        # @private
        def fhir_validators
          @fhir_validators ||= {}
        end

        def validator(name = :default, &block)
          fhir_validators[name] = Inferno::DSL::FHIRValidation::Validator.new(&block)
        end

        def find_validator(validator_name)
          validator = fhir_validators[validator_name] || parent&.find_validator(validator_name)

          raise Exceptions::ValidatorNotFoundException, validator_name if validator.nil?

          validator
        end
      end
    end
  end
end
