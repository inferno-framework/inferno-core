require 'fhir_client'
require_relative '../ext/fhir_client'

module Inferno
  module DSL
    # DSL for configuring FHIR clients
    #
    # @example
    #   input :url
    #   input :fhir_credentials, type: :oauth_credentials
    #   input :access_token
    #
    #   fhir_client do
    #     url :url
    #     headers 'My-Custom_header' => 'CUSTOM_HEADER_VALUE'
    #     oauth_credentials :fhir_credentials
    #   end
    #
    #   fhir_client :with_bearer_token do
    #     url :url
    #     bearer_token :access_token
    #   end
    class FHIRClientBuilder
      attr_accessor :runnable

      # @private
      def build(runnable, block)
        self.runnable = runnable
        instance_exec(self, &block)

        FHIR::Client.new(url).tap do |client|
          client.additional_headers = headers if headers
          client.default_json
          client.set_bearer_token bearer_token if bearer_token
          oauth_credentials&.add_to_client(client)
        end
      end

      # Define the base FHIR url for a client. A string or symbol can be provided.
      # A string is interpreted as a url. A symbol is interpreted as the name of
      # an input to the Runnable.
      #
      # @param url [String, Symbol]
      # @return [void]
      def url(url = nil)
        @url ||=
          if url.is_a? Symbol
            runnable.send(url)
          else
            url
          end&.chomp('/')
      end

      # Define the bearer token for a client. A string or symbol can be provided.
      # A string is interpreted as a token. A symbol is interpreted as the name of
      # an input to the Runnable.
      #
      # @param bearer_token [String, Symbol]
      # @return [void]
      def bearer_token(bearer_token = nil)
        @bearer_token ||=
          if bearer_token.is_a? Symbol
            runnable.send(bearer_token)
          else
            bearer_token
          end
      end

      # Define OAuth credentials for a client. These can allow a client to
      # automatically refresh its access token when it expires.
      #
      # @param oauth_credentials [Inferno::DSL::OAuthCredentials, Symbol]
      # @return [void]
      def oauth_credentials(oauth_credentials = nil)
        @oauth_credentials ||=
          if oauth_credentials.is_a? Symbol
            runnable.send(oauth_credentials)
          else
            oauth_credentials
          end
      end

      # Define custom headers for a client
      #
      # @param headers [Hash]
      # @return [void]
      def headers(headers = nil)
        @headers ||= headers
      end

      # @private
      def method_missing(name, *args, &)
        return runnable.send(name, *args, &) if runnable.respond_to? name

        super
      end

      # @private
      def respond_to_missing?(name)
        runnable.respond_to?(name) || super
      end
    end
  end
end
