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
      # @return [void]
      def assert(test, message = '')
        raise Exceptions::AssertionException, message unless test
      end

      # @private
      def bad_response_status_message(expected, received)
        "Unexpected response status: expected #{Array.wrap(expected).join(', ')}, but received #{received}"
      end

      # Check a response's status
      #
      # @param status [Integer, Array<Integer>] a single integer or an array of
      #   integer status codes
      # @param request [Inferno::Entities::Request]
      # @param response [Hash]
      # @return [void]
      def assert_response_status(status, request: self.request, response: nil)
        response ||= request&.response
        assert Array.wrap(status).include?(response[:status]), bad_response_status_message(status, response[:status])
      end

      # @private
      def bad_resource_type_message(expected, received)
        "Unexpected resource type: expected #{expected}, but received #{received}"
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
      # @return [void]
      def assert_resource_type(resource_type, resource: self.resource)
        resource_type_name = normalize_resource_type(resource_type)

        assert resource&.resourceType == resource_type_name,
               bad_resource_type_message(resource_type_name, resource&.resourceType)
      end

      # @private
      def invalid_resource_message(resource, profile_url)
        return "Resource does not conform to the profile: #{profile_url}" if profile_url.present?

        "Resource does not conform to the base #{resource&.resourceType} profile."
      end

      # Validate a FHIR resource
      #
      # @param resource [FHIR::Model]
      # @param profile_url [String] url of the profile to validate against,
      #   defaults to validating against the base FHIR resource
      # @param validator [Symbol] the name of the validator to use
      # @return [void]
      def assert_valid_resource(resource: self.resource, profile_url: nil, validator: :default)
        assert resource_is_valid?(resource:, profile_url:, validator:),
               invalid_resource_message(resource, profile_url)
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
      # @return [void]
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
      # @return [void]
      def assert_valid_json(maybe_json_string, message = '')
        assert JSON.parse(maybe_json_string)
      rescue JSON::ParserError
        assert false, "Invalid JSON. #{message}"
      end

      # Check for a valid http/https uri
      #
      # @param uri [String]
      # @param message [String] custom failure message
      # @return [void]
      def assert_valid_http_uri(uri, message = '')
        error_message = message.presence || "\"#{uri}\" is not a valid URI"
        assert uri =~ /\A#{URI::DEFAULT_PARSER.make_regexp(['http', 'https'])}\z/, error_message
      end

      # Check the Content-Type header of a response. This assertion will fail if
      # the response's content type does not begin with the provided type.
      #
      # @param type [String]
      # @param request [Inferno::Entities::Request]
      # @return [void]
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

      # Check that all Must Support elements defined on the given profile are present in the given resources.
      # Must Support elements are identified on the profile StructureDefinition and pre-parsed into metadata,
      # which may be customized prior to the check by passing a block. Alternate metadata may be provided directly.
      # Set test suite config flag debug_must_support_metadata: true to log the metadata to a file for debugging.
      #
      # @param resources [Array<FHIR::Resource>]
      # @param profile_url [String]
      # @param validator_name [Symbol] Name of the FHIR Validator that references the IG the profile is in
      # @param metadata [Hash] MustSupport Metadata (optional),
      #        if provided the check will use this instead of re-generating metadata from the profile
      # @param requirement_extension [String] Extension URL that implies "required" as an alternative to the MS flag
      # @yield [Metadata] Customize the metadata before running the test
      # @return [void]
      def assert_must_support_elements_present(resources, profile_url, validator_name: :default, metadata: nil,
                                               requirement_extension: nil, &)
        missing_elements = missing_must_support_elements(resources, profile_url, validator_name, metadata,
                                                         requirement_extension, &)
        assert missing_elements.empty?, missing_must_support_elements_message(missing_elements, resources)
      end

      # Check that all Must Support elements defined on the given profile are present in the given resources.
      # Must Support elements are identified on the profile StructureDefinition and pre-parsed into metadata,
      # which may be customized prior to the check by passing a block. Alternate metadata may be provided directly.
      # Set test suite config flag debug_must_support_metadata: true to log the metadata to a file for debugging.
      #
      # @param resources [Array<FHIR::Resource>]
      # @param profile_url [String]
      # @param validator_name [Symbol] Name of the FHIR Validator that references the IG the profile is in
      # @param metadata [Hash] MustSupport Metadata (optional),
      #        if provided the check will use this instead of re-generating metadata from the profile
      # @param requirement_extension [String] Extension URL that implies "required" as an alternative to the MS flag
      # @yield [Metadata] Customize the metadata before running the test
      # @return [Array<Boolean,String>] Boolean result and Message
      def must_support_elements_present?(resources, profile_url, validator_name: :default, metadata: nil,
                                         requirement_extension: nil, &)
        missing_elements = missing_must_support_elements(resources, profile_url, validator_name, metadata,
                                                         requirement_extension, &)

        [missing_elements.empty?, missing_must_support_elements_message(missing_elements, resources)]
      end

      # @private
      def missing_must_support_elements(resources, profile_url, validator_name, metadata, requirement_extension, &)
        rule = Inferno::DSL::FHIREvaluation::Rules::AllMustSupportsPresent.new
        debug_metadata = config.options[:debug_must_support_metadata]

        if metadata.present?
          rule.perform_must_support_test_with_metadata(resources, metadata, debug_metadata:)
        else
          ig, profile = find_ig_and_profile(profile_url, validator_name)
          rule.perform_must_support_test(profile, resources, ig, debug_metadata:, requirement_extension:, &)
        end
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

      # @private
      def missing_must_support_elements_message(missing_elements, resources)
        "Could not find #{missing_elements.join(', ')} in the #{resources.length} " \
          'provided resource(s)'
      end
    end
  end
end
