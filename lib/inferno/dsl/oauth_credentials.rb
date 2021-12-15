require_relative '../entities/attributes'

module Inferno
  module DSL
    class OAuthCredentials
      ATTRIBUTES = [
        :access_token,
        :refresh_token,
        :token_url,
        :client_id,
        :client_secret
      ].freeze

      include Entities::Attributes

      def initialize(raw_attributes_hash)
        attributes_hash = raw_attributes_hash.symbolize_keys

        invalid_keys = attributes_hash.keys - ATTRIBUTES

        raise Exceptions::UnknownAttributeException.new(invalid_keys, self.class) if invalid_keys.present?

        attributes_hash.each do |name, value|
          instance_variable_set(:"@#{name}", value)
        end
      end

      # @api private
      def to_hash
        self.class::ATTRIBUTES.each_with_object({}) do |attribute, hash|
          value = send(attribute)
          next if value.nil?

          hash[attribute] = value
        end
      end

      # @api private
      def to_s
        JSON.generate(to_hash)
      end

      # @api private
      def add_to_client(client)
        client.instance_variable_set(:@oauth_credentials, self)

        return unless access_token.present?

        client.set_bearer_token(access_token)
      end
    end
  end
end
