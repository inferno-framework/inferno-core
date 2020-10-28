require_relative 'request_storage'

module Inferno
  module DSL
    # This module contains the HTTP DSL available to test writers.
    #
    # @example
    #   class MyTestGroup < Inferno::TestGroup
    #     # create a "default" client for a group
    #     http_client do
    #       url 'https://example.com/'
    #     end
    #
    #     test :some_test do
    #       run do
    #         # performs a GET to https://example.com
    #         get
    #         # performs a GET to https://example.com/abc
    #          get('abc')
    #
    #         request  # the most recent request
    #         response # the most recent response
    #         requests # all of the requests which have been made in this test
    #       end
    #     end
    #   end
    # @see Inferno::FHIRClientBuilder Documentation for the client
    #   configuration DSL
    module HTTPClient
      # @api private
      def self.included(klass)
        klass.extend ClassMethods
        klass.include RequestStorage
      end

      # Return a previously defined HTTP client
      #
      # @param client [Symbol] the name of the client
      # @return [Faraday::Connection]
      # @see Inferno::HTTPClientBuilder
      def http_client(client = :default)
        return http_clients[client] if http_clients[client]

        definition = self.class.http_client_definitions[client]
        return nil if definition.nil?

        http_clients[client] = HTTPClientBuilder.new.build(self, definition)
      end

      # @api private
      def http_clients
        @http_clients ||= {}
      end

      # Perform an HTTP GET request
      #
      # @param url [String] if this request is using a defined client, this will
      #   be appended to the client's url. Must be an absolute url for requests
      #   made without a defined client
      # @param client [Symbol]
      # @param name [Symbol] Name for this request to allow it to be used by
      #   other tests
      # @param _options [Hash] TODO
      # @return [Inferno::Entities::Request]
      def get(url = '', client: :default, name: nil, **_options)
        store_request('outgoing', name) do
          client = http_client(client)

          if client
            client.get(url)
          elsif url.match?(%r{\Ahttps?://})
            Faraday.get(url)
          else
            raise StandardError, 'Must use an absolute url or define an HTTP client with a base url'
          end
        end
      end

      # Perform an HTTP POST request
      #
      # @param url [String] if this request is using a defined client, this will
      #   be appended to the client's url. Must be an absolute url for requests
      #   made without a defined client
      # @param body [String]
      # @param client [Symbol]
      # @param name [Symbol] Name for this request to allow it to be used by
      #   other tests
      # @param _options [Hash] TODO
      # @return [Inferno::Entities::Request]
      def post(url = '', body: nil, client: :default, name: nil, **_options)
        store_request('outgoing', name) do
          client = http_client(client)

          if client
            client.post(url, body)
          elsif url.match?(%r{\Ahttps?://})
            Faraday.post(url, body)
          else
            raise StandardError, 'Must use an absolute url or define an HTTP client with a base url'
          end
        end
      end

      module ClassMethods
        # @api private
        def http_client_definitions
          @http_client_definitions ||= {}
        end

        # Define a HTTP client to be used by a Runnable.
        #
        # @param name [Symbol] a name used to reference this particular client
        # @param block a block to configure the client
        # @see Inferno::HTTPClientBuilder Documentation for the client
        #   configuration DSL
        def http_client(name = :default, &block)
          http_client_definitions[name] = block
        end
      end
    end
  end
end
