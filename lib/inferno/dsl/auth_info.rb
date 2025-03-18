require_relative '../entities/attributes'
require_relative 'jwks'

module Inferno
  module DSL
    # AuthInfo provides a user with a single input which contains the information
    # needed for a FHIR client to perform authorization and refresh an access
    # token when necessary.
    #
    # AuthInfo supports the following `auth_type`:
    #
    #   - `public` - Client id only
    #   - `symmetric` - Confidential symmetric (i.e., with a static client id and
    #     secret)
    #   - `asymmetric` - Confidential asymmetric (i.e., a client id with a signed
    #     JWT rather than a client secret)
    #   - `backend_services`
    #
    # When configuring an AuthInfo input, the invdidual fields are exposed as
    # `components` in the input's options, and can be configured there similar
    # to normal inputs.
    #
    # The AuthInfo input type supports two different modes in the UI. Different
    # fields will be presented to the user depending on which mode is selected:
    #
    #   - `auth` - This presents the inputs needed to perform authorization, and
    #     is appropriate to use as an input to test groups which perform
    #     authorization.
    #   - `access` - This presents the inputs needed to access resources assuming
    #     that authorization has already happened, and is appropriate to use as an
    #     input to test groups which access resources using previously granted
    #     authorization.
    #
    # @example
    #   class AuthInfoExampleSuite < Inferno::TestSuite
    #     input :url,
    #           title: 'Base FHIR url'
    #
    #     group do
    #       title 'Perform public authorization'
    #       input :fhir_auth,
    #             type: :auth_info,
    #             options: {
    #               mode: 'auth',
    #               components: [
    #                 {
    #                   name: :auth_type,
    #                   default: 'public',
    #                   locked: true
    #                 }
    #               ]
    #             }
    #
    #       # Some tests here to perform authorization
    #     end
    #
    #     group do
    #       title 'FHIR API Tests'
    #       input :fhir_auth,
    #             type: :auth_info,
    #             options: {
    #               mode: 'access'
    #             }
    #
    #       fhir_client do
    #         url :url
    #         auth_info :fhir_auth
    #       end
    #
    #       # Some tests here to access FHIR API
    #     end
    #   end
    class AuthInfo
      ATTRIBUTES = [
        :auth_type,
        :use_discovery,
        :token_url,
        :auth_url,
        :requested_scopes,
        :client_id,
        :client_secret,
        :redirect_url, # TODO: does this belong here?
        :pkce_support,
        :pkce_code_challenge_method,
        :auth_request_method,
        :encryption_algorithm,
        :kid,
        :jwks,
        :access_token,
        :refresh_token,
        :issue_time,
        :expires_in,
        :name
      ].freeze

      include Entities::Attributes

      attr_accessor :client

      # @!attribute [rw] auth_type
      #   The type of authorization to be performed. One of `public`, `symmetric`, `asymmetric`, or `backend_services`
      # @!attribute [rw] token_url
      #   The url of the auth server's token endpoint
      # @!attribute [rw] auth_url
      #   The url of the authorization endpoint
      # @!attribute [rw] requested_scopes
      #   The scopes which will be requested during authorization
      # @!attribute [rw] client_id
      # @!attribute [rw] client_secret
      # @!attribute [rw] redirect_url
      # @!attribute [rw] pkce_support
      #   Whether PKCE will be used during authorization. Either `enabled` or `disabled`.
      # @!attribute [rw] pkce_code_challenge_method
      #   Either `S256` (default) or `plain`
      # @!attribute [rw] auth_request_method
      #   The http method which will be used to perform the request to the authorization endpoint.
      #   Either `get` (default) or `post`
      # @!attribute [rw] encryption_algorithm
      #   The encryption algorithm which will be used to sign the JWT client credentials.
      #   Either `es384` (default) or `rs384`
      # @!attribute [rw] kid
      #   The key id for the keys to be used to sign the JWT client credentials.
      #   When blank, the first key for the selected encryption algorithm will be used
      # @!attribute [rw] jwks
      #   A JWKS (including private keys) which will be used instead of Inferno's default JWKS if provided
      # @!attribute [rw] access_token
      # @!attribute [rw] refresh_token
      # @!attribute [rw] issue_time
      #   An iso8601 formatted string representing the time the access token was issued
      # @!attribute [rw] expires_in
      #   The lifetime of the access token in seconds
      # @!attribute [rw] name

      # @private
      def initialize(raw_attributes_hash)
        attributes_hash = raw_attributes_hash.symbolize_keys

        invalid_keys = attributes_hash.keys - ATTRIBUTES

        raise Exceptions::UnknownAttributeException.new(invalid_keys, self.class) if invalid_keys.present?

        attributes_hash.each do |name, value|
          value = DateTime.parse(value) if name == :issue_time && value.is_a?(String)

          instance_variable_set(:"@#{name}", value)
        rescue Date::Error
          Inferno::Application['logger'].error("Received invalid date: #{value.inspect}")
        end

        self.issue_time = DateTime.now if access_token.present? && issue_time.blank?
      end

      # @private
      def to_hash
        self.class::ATTRIBUTES.each_with_object({}) do |attribute, hash|
          value = send(attribute)
          next if value.nil?

          value = issue_time.iso8601 if attribute == :issue_time

          hash[attribute] = value
        end
      end

      # @private
      def to_s
        JSON.generate(to_hash)
      end

      # @private
      def add_to_client(client)
        client.auth_info = self
        self.client = client
        # TODO: do we want to perform authorization if no access_token or rely on SMART/ other auth tests?
        return unless access_token.present?

        client.set_bearer_token(access_token)
      end

      # @private
      def need_to_refresh?
        return false if access_token.blank? || (!backend_services? && refresh_token.blank?)

        return true if expires_in.blank?

        issue_time.to_i + expires_in.to_i - DateTime.now.to_i < 60
      end

      # @private
      def able_to_refresh?
        token_url.present? && (backend_services? || refresh_token.present?)
      end

      # @private
      def backend_services?
        auth_type == 'backend_services'
      end

      # @private
      def oauth2_refresh_params
        case auth_type
        when 'public'
          public_auth_refresh_params
        when 'symmetric'
          symmetric_auth_refresh_params
        when 'asymmetric'
          asymmetric_auth_refresh_params
        when 'backend_services'
          backend_services_auth_refresh_params
        end
      end

      # @private
      def symmetric_auth_refresh_params
        {
          'grant_type' => 'refresh_token',
          'refresh_token' => refresh_token
        }
      end

      # @private
      def public_auth_refresh_params
        symmetric_auth_refresh_params.merge('client_id' => client_id)
      end

      # @private
      def asymmetric_auth_refresh_params
        symmetric_auth_refresh_params.merge(
          'client_assertion_type' => 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
          'client_assertion' => client_assertion
        )
      end

      # @private
      def backend_services_auth_refresh_params
        {
          'grant_type' => 'client_credentials',
          'scope' => requested_scopes,
          'client_assertion_type' => 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
          'client_assertion' => client_assertion
        }
      end

      # @private
      def oauth2_refresh_headers
        base_headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

        return base_headers unless auth_type == 'symmetric'

        credentials = "#{client_id}:#{client_secret}"

        base_headers.merge(
          'Authorization' => "Basic #{Base64.strict_encode64(credentials)}"
        )
      end

      # @private
      def private_key
        @private_key ||= JWKS.jwks(user_jwks: jwks)
          .select { |key| key[:key_ops]&.include?('sign') }
          .select { |key| key[:alg] == encryption_algorithm }
          .find { |key| !kid || key[:kid] == kid }
      end

      # @private
      def signing_key
        if private_key.nil?
          raise Inferno::Exceptions::AssertionException,
                "No signing key found for inputs: encryption method = '#{encryption_algorithm}' and kid = '#{kid}'"
        end

        @private_key.signing_key
      end

      # @private
      def auth_jwt_header
        {
          'alg' => encryption_algorithm,
          'kid' => private_key['kid'],
          'typ' => 'JWT',
          'jku' => Inferno::Application['jwks_url']
        }
      end

      # @private
      def auth_jwt_claims
        {
          'iss' => client_id,
          'sub' => client_id,
          'aud' => token_url,
          'exp' => 5.minutes.from_now.to_i,
          'jti' => SecureRandom.hex(32)
        }
      end

      # @private
      def client_assertion
        JWT.encode auth_jwt_claims, signing_key, encryption_algorithm, auth_jwt_header
      end

      # @private
      def update_from_response_body(request)
        token_response_body = JSON.parse(request.response_body)

        expires_in = token_response_body['expires_in'].is_a?(Numeric) ? token_response_body['expires_in'] : nil

        self.access_token = token_response_body['access_token']
        self.refresh_token = token_response_body['refresh_token'] if token_response_body['refresh_token'].present?
        self.expires_in = expires_in
        self.issue_time = DateTime.now

        add_to_client(client) if client
        self
      end

      # Returns the default configuration for the "auth_type" component
      # @return [Hash]
      def self.default_auth_type_component
        {
          name: :auth_type,
          options: {
            list_options: [
              { label: 'Public', value: 'public' },
              { label: 'Confidential Symmetric', value: 'symmetric' },
              { label: 'Confidential Asymmetric', value: 'asymmetric' },
              { label: 'Backend Services', value: 'backend_services' }
            ]
          }
        }
      end

      # Returns the default configuration for the "auth_type" component without
      # the option for backend services auth
      # @return [Hash]
      def self.default_auth_type_component_without_backend_services
        {
          name: :auth_type,
          options: {
            list_options: [
              { label: 'Public', value: 'public' },
              { label: 'Confidential Symmetric', value: 'symmetric' },
              { label: 'Confidential Asymmetric', value: 'asymmetric' }
            ]
          }
        }
      end

      # Returns true when using public auth
      # @return [Boolean]
      def public_auth?
        auth_type&.casecmp? 'public'
      end

      # Returns true when using confidential symmetric auth
      # @return [Boolean]
      def symmetric_auth?
        auth_type&.casecmp? 'symmetric'
      end

      # Returns true when using confidential asymmetric auth
      # @return [Boolean]
      def asymmetric_auth?
        auth_type&.casecmp? 'asymmetric'
      end

      # Returns true when using backend services auth
      # @return [Boolean]
      def backend_services_auth?
        auth_type&.casecmp? 'backend_services'
      end

      # Returns true when using GET as the authorization request method
      # @return [Boolean]
      def get_auth_request?
        auth_request_method&.casecmp? 'get'
      end

      # Returns true when using POST as the authorization request method
      # @return [Boolean]
      def post_auth_request?
        auth_request_method&.casecmp? 'post'
      end

      # Returns true when pkce is enabled
      # @return [Boolean]
      def pkce_enabled?
        pkce_support&.casecmp? 'enabled'
      end

      # Returns true when using the S256 pkce code challenge method
      # @return [Boolean]
      def s256_code_challenge_method?
        pkce_code_challenge_method&.casecmp? 'S256'
      end

      # Returns true when using the palin pkce code challenge method
      # @return [Boolean]
      def plain_code_challenge_method?
        pkce_code_challenge_method&.casecmp? 'plain'
      end
    end
  end
end
