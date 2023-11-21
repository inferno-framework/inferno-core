require 'faraday_middleware'

require_relative 'http_client_builder'
require_relative 'request_storage'
require_relative 'tcp_exception_handler'

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
    #         get('abc')
    #
    #         request  # the most recent request
    #         response # the most recent response
    #         requests # all of the requests which have been made in this test
    #       end
    #     end
    #   end
    # @see Inferno::DSL::HTTPClientBuilder Documentation for the client
    #   configuration DSL
    module HTTPClient
      # @private
      def self.included(klass)
        klass.extend ClassMethods
        klass.include RequestStorage
        klass.include TCPExceptionHandler
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

        tcp_exception_handler do
          http_clients[client] = HTTPClientBuilder.new.build(self, definition)
        end
      end

      # @private
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
      # @param headers [Hash] Input headers here
      # @param tags [Array<String>] a list of tags to assign to the request
      # @return [Inferno::Entities::Request]
      def get(url = '', client: :default, name: nil, headers: nil, tags: [])
        store_request('outgoing', name, tags) do
          tcp_exception_handler do
            client = http_client(client)

            if client
              client.get(url, nil, headers)
            elsif url.match?(%r{\Ahttps?://})
              connection.get(url, nil, headers)
            else
              raise StandardError, 'Must use an absolute url or define an HTTP client with a base url'
            end
          end
        end
      end

      # @private
      def connection
        Faraday.new do |f|
          f.request :url_encoded
          f.use FaradayMiddleware::FollowRedirects
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
      # @param headers [Hash] Input headers here
      # @param tags [Array<String>] a list of tags to assign to the request
      # @return [Inferno::Entities::Request]
      def post(url = '', body: nil, client: :default, name: nil, headers: nil, tags: [])
        store_request('outgoing', name, tags) do
          tcp_exception_handler do
            client = http_client(client)

            if client
              client.post(url, body, headers)
            elsif url.match?(%r{\Ahttps?://})
              connection.post(url, body, headers)
            else
              raise StandardError, 'Must use an absolute url or define an HTTP client with a base url'
            end
          end
        end
      end

      # Perform an HTTP DELETE request
      #
      # @param url [String] if this request is using a defined client, this will
      #   be appended to the client's url. Must be an absolute url for requests
      #   made without a defined client
      # @param client [Symbol]
      # @param name [Symbol] Name for this request to allow it to be used by
      #   other tests
      # @param headers [Hash] Input headers here
      # @param tags [Array<String>] a list of tags to assign to the request
      # @return [Inferno::Entities::Request]
      def delete(url = '', client: :default, name: :nil, headers: nil, tags: [])
        store_request('outgoing', name, tags) do
          tcp_exception_handler do
            client = http_client(client)

            if client
              client.delete(url, nil, headers)
            elsif url.match?(%r{\Ahttps?://})
              connection.delete(url, nil, headers)
            else
              raise StandardError, 'Must use an absolute url or define an HTTP client with a base url'
            end
          end
        end
      end

      # Perform an HTTP GET request and stream the response
      #
      # @param block [Proc] A Proc object whose input will be the string chunks
      #   received while streaming response to the get request.
      # @param url [String] If this request is using a defined client, this will
      #   be appended to the client's url. Must be an absolute url for requests
      #   made without a defined client
      # @param limit [Integer] The number of streamed-in chunks to be stored in
      #   the response body. This optional input defaults to 100.
      # @param client [Symbol]
      # @param name [Symbol] Name for this request to allow it to be used by
      #   other tests
      # @param headers [Hash] Input headers here
      # @param tags [Array<String>] a list of tags to assign to the request
      # @return [Inferno::Entities::Request]
      def stream(block, url = '', limit = 100, client: :default, name: nil, headers: nil, tags: [])
        streamed = []

        collector = proc do |chunk, bytes|
          streamed << chunk if limit.positive?
          limit -= 1
          block.call(chunk, bytes)
        end

        store_request('outgoing', name, tags) do
          tcp_exception_handler do
            client = http_client(client)

            if client
              response = client.get(url, nil, headers) { |req| req.options.on_data = collector }
            elsif url.match?(%r{\Ahttps?://})
              response = connection.get(url, nil, headers) { |req| req.options.on_data = collector }
            else
              raise StandardError, 'Must use an absolute url or define an HTTP client with a base url'
            end
            response.env.body = streamed.join
            response
          end
        end
      end

      module ClassMethods
        # @private
        def http_client_definitions
          @http_client_definitions ||= {}
        end

        # Define a HTTP client to be used by a Runnable.
        #
        # @param name [Symbol] a name used to reference this particular client
        # @param block a block to configure the client
        # @see Inferno::HTTPClientBuilder Documentation for the client
        #   configuration DSL
        # @return [void]
        def http_client(name = :default, &block)
          http_client_definitions[name] = block
        end
      end
    end
  end
end
