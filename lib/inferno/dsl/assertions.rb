require_relative '../exceptions'

module Inferno
  module DSL
    module Assertions
      def assert(test, message = '')
        raise Exceptions::AssertionException, message unless test
      end

      def bad_response_status_message(expected, received)
        "Bad response status: expected #{Array.wrap(expected).join(', ')}, but received #{received}"
      end

      def assert_response_status(status, response: self.response)
        assert Array.wrap(status).include?(response[:status]), bad_response_status_message(status, response[:status])
      end

      def bad_resource_type_message(expected, received)
        "Bad resource type received: expected #{expected}, but received #{received}"
      end

      def assert_resource_type(resource_type, resource: self.resource)
        resource_type_name = normalize_resource_type(resource_type)

        assert resource&.resourceType == resource_type_name,
               bad_resource_type_message(resource_type_name, resource&.resourceType)
      end

      def invalid_resource_message(profile_url)
        "Resource does not conform to the profile: #{profile_url}"
      end

      def assert_valid_resource(resource: self.resource, profile_url: nil)
        assert resource_is_valid?(resource: resource, profile_url: profile_url),
               invalid_resource_message(profile_url)
      end

      def assert_valid_bundle_entries(bundle: resource, resource_types: {})
        assert_resource_type('Bundle', resource: bundle)

        types_to_check = normalize_types_to_check(resource_types)

        invalid_resources =
          bundle
            .entry
            .map(&:resource)
            .select { |resource| types_to_check.empty? || types_to_check.include?(resource.resourceType) }
            .reject do |resource|
              validation_params = { resource: resource }
              profile = types_to_check[resource.resourceType]
              validation_params[:profile_url] = profile if profile

              resource_is_valid?(**validation_params)
            end

        assert invalid_resources.empty?, invalid_bundle_entries_message(invalid_resources)
      end

      def invalid_bundle_entries_message(invalid_resources)
        identifier_strings =
          invalid_resources
            .map { |resource| "#{resource.resourceType}##{resource.id}" }
            .join(', ')
        "The following bundle entries are invalid: #{identifier_strings}"
      end

      def normalize_resource_type(resource_type)
        if resource_type.is_a? Class
          resource_type.name.demodulize
        else
          resource_type.to_s.camelize
        end
      end

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

      def assert_valid_json(maybe_json_string, message = '')
        assert JSON.parse(maybe_json_string)
      rescue JSON::ParserError
        assert false, "Invalid JSON. #{message}"
      end

      def assert_valid_http_uri(uri, message = '')
        error_message = message || "\"#{uri}\" is not a valid URI"
        assert uri =~ /\A#{URI::DEFAULT_PARSER.make_regexp(['http', 'https'])}\z/, error_message
      end

      def assert_response_ok(response: self.response, error_message: '')
        message = "Bad response code: expected 200, 201, but found #{response.code}. #{error_message}"
        assert [200, 201].include?(response.code), message
      end
    end
  end
end
