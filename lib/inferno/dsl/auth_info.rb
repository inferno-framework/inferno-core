require_relative '../entities/attributes'

module Inferno
  module DSL
    # AuthInfo provide a user with a single input which contains the information
    # needed for a fhir client to perform authorization and refresh an access
    # token when necessary.
    #
    # AuthInfo supports the following `auth_type`:
    # - `public` - client id only
    # - `symmetric` - Symmetric confidential (i.e., with a static client id and
    #   secret)
    # - `asymmetric` - Symmetric confidential (i.e., a client id with a signed
    #   JWT rather than a client secret)
    # - `backend_services`
    #
    # When configuring an AuthInfo input, the invdidual fields are exposed as
    # `components` in the input's options, and can be configured there similar
    # to normal inputs.
    #
    # The AuthInfo input type supports two different modes in the UI. Different
    # fields will be presented to the user depending on which mode is selected.
    # - `auth` - This presents the inputs needed to perform authorization, and
    #   is appropriate to use as an input to test groups which perform
    #   authorization
    # - `access` - This presents the inputs needed to access resources assuming
    #   that authorization has already happened, and is appropriate to use as an
    #   input to test groups which access resources using previously granted
    #   authorization
    #
    # @example
    # class AuthInfoExampleSuite < Inferno::TestSuite
    #   input :url,
    #         title: 'Base FHIR url'
    #
    #   group do
    #     title 'Perform public authorization'
    #     input :fhir_auth,
    #           type: :auth_info,
    #           options: {
    #             mode: 'auth',
    #             components: [
    #               {
    #                 name: :auth_type,
    #                 default: 'public',
    #                 locked: true
    #               }
    #             ]
    #           }
    #
    #     # Some tests here to perform authorization
    #   end
    #
    #   group do
    #     title 'FHIR API Tests'
    #     input :fhir_auth,
    #           type: :auth_info,
    #           options: {
    #             mode: 'access'
    #           }
    #
    #     fhir_client do
    #       url :url
    #       auth_info :fhir_auth # NOT YET IMPLEMENTED
    #     end
    #
    #     # Some tests here to access FHIR API
    #   end
    # end
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

      # @!attribute [rw] auth_type The type of authorization to be performed.
      #   One of `public`, `symmetric`, `asymmetric`, or `backend_services`
      # @!attribute [rw] token_url The url of the auth server's token endpoint
      # @!attribute [rw] auth_url The url of the authorization endpoint
      # @!attribute [rw] requested_scopes The scopes which will be requested
      #   during authorization
      # @!attribute [rw] client_id
      # @!attribute [rw] client_secret
      # @!attribute [rw] redirect_url
      # @!attribute [rw] pkce_support Whether PKCE will be used during
      #   authorization. Either `enabled` or `disabled`.
      # @!attribute [rw] pkce_code_challenge_method Either `S256` (default) or
      #   `plain`
      # @!attribute [rw] auth_request_method The http method which will be used
      #   to perform the request to the authorization endpoint. Either `get`
      #   (default) or `post`
      # @!attribute [rw] encryption_algorithm The encryption algorithm which
      #   will be used to sign the JWT client credentials. Either `es384`
      #   (default) or `rs384`
      # @!attribute [rw] kid The key id for the keys to be used to sign the JWT
      #   client credentials. When blank, the first key for the selected
      #   encryption algorithm will be used
      # @!attribute [rw] jwks A JWKS (including private keys) which will be used
      #   instead of Inferno's default JWKS if provided
      # @!attribute [rw] access_token
      # @!attribute [rw] refresh_token
      # @!attribute [rw] issue_time An iso8601 formatted string representing the
      #   time the access token was issued
      # @!attribute [rw] expires_in The lifetime of the access token in seconds
      # @!attribute [rw] name

      # @private
      def initialize(raw_attributes_hash)
        attributes_hash = raw_attributes_hash.symbolize_keys

        invalid_keys = attributes_hash.keys - ATTRIBUTES

        raise Exceptions::UnknownAttributeException.new(invalid_keys, self.class) if invalid_keys.present?

        attributes_hash.each do |name, value|
          value = DateTime.parse(value) if name == :issue_time && value.is_a?(String)

          instance_variable_set(:"@#{name}", value)
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
    end
  end
end
