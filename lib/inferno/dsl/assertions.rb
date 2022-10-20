require_relative '../exceptions'

module Inferno
  module DSL
    # This module contains the assertions used within tests to verify the
    # behavior of the systems under test. Failing an assertion causes a test to
    # immediately stop execution and receive a `fail` result. Additional
    # assertions added to this module will be available in all tests.
    module Assertions
      # Make an assertion
      #
      # @param test a value whose truthiness will determine whether the
      #   assertion passes or fails
      # @param message [String] failure message
      def assert(test, message = '')
        raise Exceptions::AssertionException, message unless test
      end

      # @private
      def bad_response_status_message(expected, received)
        "Bad response status: expected #{Array.wrap(expected).join(', ')}, but received #{received}"
      end

      # Check an response's status
      #
      # @param status [Integer, Array<Integer>] a single integer or an array of
      #   integer status codes
      # @param response [Hash]
      def assert_response_status(status, response: self.response)
        assert Array.wrap(status).include?(response[:status]), bad_response_status_message(status, response[:status])
      end

      # @private
      def bad_resource_type_message(expected, received)
        "Bad resource type received: expected #{expected}, but received #{received}"
      end

      # Check a FHIR resource's type
      #
      # @param resource_type [String, Symbol, Class]
      # @param resource [FHIR::Model]
      # @example
      #   # The resource type can be a symbol, String, or FHIR::Model class
      #   assert_resource_type(:capability_statement)
      #   assert_resource_type('CapabilityStatement')
      #   assert_resource_type(FHIR::CapabilityStatement)
      def assert_resource_type(resource_type, resource: self.resource)
        resource_type_name = normalize_resource_type(resource_type)

        assert resource&.resourceType == resource_type_name,
               bad_resource_type_message(resource_type_name, resource&.resourceType)
      end

      # @private
      def invalid_resource_message(profile_url)
        "Resource does not conform to the profile: #{profile_url}"
      end

      # Validate a FHIR resource
      #
      # @param resource [FHIR::Model]
      # @param profile_url [String] url of the profile to validate against,
      #   defaults to validating against the base FHIR resource
      def assert_valid_resource(resource: self.resource, profile_url: nil)
        assert resource_is_valid?(resource:, profile_url:),
               invalid_resource_message(profile_url)
      end

      # Validate each entry of a Bundle
      #
      # @param bundle [FHIR::Bundle]
      # @param resource_types
      # [String,Symbol,FHIR::Model,Array<String,Symbol,FHIR::Model>,Hash] If a
      #   string, symbol, or FHIR::Model is provided, only that resource type
      #   will be validated. If an array of strings is provided, only those
      #   resource types will be validated. If a hash is provided with resource
      #   types as keys and profile urls (or nil) as values, only those resource
      #   types will be validated against the provided profile url or the base
      #   resource if nil.
      # @example
      #   # Only validate Patient bundle entries
      #   assert_valid_bundle_entries(resource_types: 'Patient')
      #
      #   # Only valiadte Patient and Condition bundle entries
      #   assert_valid_bundle_entries(resource_types: ['Patient', 'Condition'])
      #
      #   # Only validate Patient and Condition bundle entries. Validate Patient
      #   # resources against the given profile, and Codition resources against the
      #   # base FHIR Condition resource.
      #   assert_valid_bundle_entries(
      #     resource_types: {
      #       'Patient': 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient',
      #       'Condition': nil
      #     }
      #   )
      def assert_valid_bundle_entries(bundle: resource, resource_types: {})
        assert_resource_type('Bundle', resource: bundle)

        types_to_check = normalize_types_to_check(resource_types)

        invalid_resources =
          bundle
            .entry
            .map(&:resource)
            .select { |resource| types_to_check.empty? || types_to_check.include?(resource.resourceType) }
            .reject do |resource|
              validation_params = { resource: }
              profile = types_to_check[resource.resourceType]
              validation_params[:profile_url] = profile if profile

              resource_is_valid?(**validation_params)
            end

        assert invalid_resources.empty?, invalid_bundle_entries_message(invalid_resources)
      end

      # @private
      def invalid_bundle_entries_message(invalid_resources)
        identifier_strings =
          invalid_resources
            .map { |resource| "#{resource.resourceType}##{resource.id}" }
            .join(', ')
        "The following bundle entries are invalid: #{identifier_strings}"
      end

      # @private
      def normalize_resource_type(resource_type)
        if resource_type.is_a? Class
          resource_type.name.demodulize
        else
          resource_type.to_s.camelize
        end
      end

      # @private
      def normalize_types_to_check(resource_types)
        case resource_types
        when Hash
          resource_types.transform_keys { |type| normalize_resource_type(type) }
        when String
          { normalize_resource_type(resource_types) => nil }
        when Array
          resource_types.each_with_object({}) { |type, types| types[normalize_resource_type(type)] = nil }
        end
      end

      # Check for valid JSON
      #
      # @param maybe_json_string [String]
      # @param message [String] extra failure message
      def assert_valid_json(maybe_json_string, message = '')
        assert JSON.parse(maybe_json_string)
      rescue JSON::ParserError
        assert false, "Invalid JSON. #{message}"
      end

      # Check for a valid http/https uri
      #
      # @param uri [String]
      # @param message [String] custom failure message
      def assert_valid_http_uri(uri, message = '')
        error_message = message.presence || "\"#{uri}\" is not a valid URI"
        assert uri =~ /\A#{URI::DEFAULT_PARSER.make_regexp(['http', 'https'])}\z/, error_message
      end

      # Check the Content-Type header of a response
      #
      # @param type [String]
      # @param request [Inferno::Entities::Request]
      def assert_response_content_type(type, request: self.request)
        header = request.response_header('Content-Type')
        assert header.present?, no_content_type_message

        assert header.value.start_with?(type), bad_content_type_message(type, header.value)
      end

      # @private
      def no_content_type_message
        'Response did not contain a `Content-Type` header.'
      end

      # @private
      def bad_content_type_message(expected, received)
        "Expected `Content-Type` to be `#{expected}`, but found `#{received}`"
      end
    end
  end
end
