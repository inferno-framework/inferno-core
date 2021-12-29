require_relative '../entities/attributes'

module Inferno
  module DSL
    class OAuthCredentials
      ATTRIBUTES = [
        :access_token,
        :refresh_token,
        :token_url,
        :client_id,
        :client_secret,
        :token_retrieval_time,
        :expires_in,
        :name
      ].freeze

      include Entities::Attributes

      attr_accessor :client

      def initialize(raw_attributes_hash)
        attributes_hash = raw_attributes_hash.symbolize_keys

        invalid_keys = attributes_hash.keys - ATTRIBUTES

        raise Exceptions::UnknownAttributeException.new(invalid_keys, self.class) if invalid_keys.present?

        attributes_hash.each do |name, value|
          value = DateTime.parse(value) if name == :token_retrieval_time && value.is_a?(String)

          instance_variable_set(:"@#{name}", value)
        end

        self.token_retrieval_time = DateTime.now if token_retrieval_time.blank?
      end

      # @api private
      def to_hash
        self.class::ATTRIBUTES.each_with_object({}) do |attribute, hash|
          value = send(attribute)
          next if value.nil?

          value = token_retrieval_time.iso8601 if attribute == :token_retrieval_time

          hash[attribute] = value
        end
      end

      # @api private
      def to_s
        JSON.generate(to_hash)
      end

      # @api private
      def add_to_client(client)
        client.oauth_credentials = self
        self.client = client

        return unless access_token.present?

        client.set_bearer_token(access_token)
      end

      # @api private
      def need_to_refresh?
        return false if access_token.blank? || refresh_token.blank?

        return true if expires_in.blank?

        token_retrieval_time.to_i + expires_in - DateTime.now.to_i < 60
      end

      # @api private
      def able_to_refresh?
        refresh_token.present? && token_url.present?
      end

      # @api private
      def confidential_client?
        client_id.present? && client_secret.present?
      end

      # @api private
      def oauth2_refresh_params
        {
          'grant_type' => 'refresh_token',
          'refresh_token' => refresh_token
        }
      end

      # @api private
      def oauth2_refresh_headers
        base_headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

        return base_headers unless confidential_client?

        credentials = "#{client_id}:#{client_secret}"

        base_headers.merge(
          'Authorization' => "Basic #{Base64.strict_encode64(credentials)}"
        )
      end

      def update_from_response_body(request)
        token_response_body = JSON.parse(request.response_body)

        expires_in = token_response_body['expires_in'].is_a?(Numeric) ? token_response_body['expires_in'] : nil

        self.access_token = token_response_body['access_token']
        self.refresh_token = token_response_body['refresh_token']
        self.expires_in = expires_in
        self.token_retrieval_time = DateTime.now

        add_to_client(client)
        self
      end
    end
  end
end
