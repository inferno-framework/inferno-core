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

      def assert_security_protocol(uri, action, version)
        assert uri.downcase.starts_with?('https'), "URI is not HTTPS: #{uri}", uri_not_https_details(uri)
        
        tls_tester = TlsTester.new(uri: uri)
        begin
          passed, message, details = tls_tester.verify_protocol(action, string_to_protocol(version), version)
          assert passed, message, details
        rescue AssertionException => e
          raise e
        rescue SocketError => e
          assert false, "Unable to connect to #{uri}: #{e.message}", tls_socket_error_details(uri)
        rescue StandardError => e
          assert false,
                 "Unable to connect to #{uri}: #{e.class.name}, #{e.message}",
                 tls_unexpected_error_details(uri)
        end
      end 

      def assert_strict_verify_protocol(uri, action, version)
        assert uri.downcase.starts_with?('https'), "URI is not HTTPS: #{uri}", uri_not_https_details(uri)
        protocols = ['SSLv2.0', 'SSLv3.0', 'TLSv1.0', 'TLSv1.1', 'TLSv1.2', 'TLSv1.3']
        unsupported_protocols = protocols.slice(0, protocols.index(version))

        begin 
          assert_security_protocol(uri, string_to_protocol(version))
          for protocol in unsupported_protocols
            assert_security_protocol(uri, 'deny', string_to_protocol(protocol))
          end 
        rescue AssertionException => e
          raise e
        end
      end

      def string_to_protocol(version)
        case version
        when 'SSLv2.0'
          return OpenSSL::SSL::SSL2_VERSION
        when 'SSLv3.0'
          return OpenSSL::SSL::SSL3_VERSION
        when 'TLSv1.0'
          return OpenSSL::SSL::TLS1_VERSION
        when 'TLSv1.1'
          return OpenSSL::SSL::TLS1_1_VERSION
        when 'TLSv1.3'
          return OpenSSL::SSL::TLS1_3_VERSION
        else 
          return OpenSSL::SSL::TLS1_2_VERSION
        end
      end 

      def uri_not_https_details(uri)
        %(
          The following URI does not use the HTTPS protocol identifier:
  
          [#{uri}](#{uri})
  
          The HTTPS protocol identifier is required for TLS connections.
  
          HTTP/TLS is differentiated from HTTP by using the `https`
          protocol identifier in place of the `http` protocol identifier. An
          example URI specifying HTTP/TLS is:
          `https://www.example.org`
  
          [HTTP Over TLS](https://tools.ietf.org/html/rfc2818#section-2.4)
  
  
          In order to fix this error you must secure this endpoint with TLS 1.2
          and ensure that references to this URL point to the HTTPS protocol so
          that use of TLS is explicit.
        ) + disable_tls_instructions
      end

      def tls_socket_error_details(uri)
        %(
          The following URI did not accept socket connections over port 443:
  
          [#{uri}](#{uri})
  
          ```
          When HTTP/TLS is being run over a TCP/IP connection, the default port
          is 443.
          ```
          [HTTP Over TLS](https://tools.ietf.org/html/rfc2818#section-2.3)
  
  
          To fix this error ensure that this URI is protected by TLS.
        ) + disable_tls_instructions
      end

      def tls_unexpected_error_details(uri)
        %(
          An unexpected error occured when attempting to connect to the
          following URI using TLS.
  
          [#{uri}](#{uri})
  
          To fix this error ensure that this URI is protected by TLS.
        ) + disable_tls_instructions
      end

      def disable_tls_instructions
        %(
          You may safely ignore this error if this environment does not secure
          content using TLS. If you are running a local copy of Inferno you
          can turn off TLS detection by changing setting the
          `disable_tls_tests` option to true in `config.yml`.
        )
      end
    end
  end
end
