require_relative '../entities/attributes'

module Inferno
  module DSL
    # AuthInfo provide a user with a single input which allows a fhir client to
    # use a bearer token and automatically refresh the token when it expires.
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
        # :certificate, TODO
        :access_token,
        :refresh_token,
        :issue_time,
        :expires_in,
        :name
      ].freeze

      include Entities::Attributes

      attr_accessor :client

      # @!attribute [rw] auth_type
      # @!attribute [rw] token_url
      # @!attribute [rw] auth_url
      # @!attribute [rw] requested_scopes
      # @!attribute [rw] client_id
      # @!attribute [rw] client_secret
      # @!attribute [rw] redirect_url
      # @!attribute [rw] pkce_support
      # @!attribute [rw] pkce_code_challenge_method
      # @!attribute [rw] auth_request_method
      # @!attribute [rw] encryption_algorithm
      # @!attribute [rw] kid
      # @!attribute [rw] jwks
      # @!attribute [rw] access_token
      # @!attribute [rw] refresh_token
      # @!attribute [rw] issue_time
      # @!attribute [rw] expires_in
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
        # TODO
        # client.auth = self
        # self.client = client

        # return unless access_token.present?

        # client.set_bearer_token(access_token)
      end
    end
  end
end
