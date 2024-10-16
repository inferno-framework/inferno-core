require 'faraday_middleware'

module Inferno
  module DSL
    # This module contains the HTTP DSL available to test writers.
    class HTTPClientBuilder
      attr_accessor :runnable

      # @private
      def build(runnable, block)
        self.runnable = runnable
        instance_exec(self, &block)

        params = { url: }
        params.merge!(headers:) if headers

        Faraday.new(params) do |f|
          f.request :url_encoded
          f.use FaradayMiddleware::FollowRedirects
        end
      end

      # Define the base url for an HTTP client. A string or symbol can be
      # provided. A string is interpreted as a url. A symbol is interpreted as
      # the name of an input to the Runnable.
      #
      # @param url [String, Symbol]
      # @return [void]
      def url(url = nil)
        @url ||=
          if url.is_a? Symbol
            runnable.send(url)
          else
            url
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
      def method_missing(name, ...)
        return runnable.send(name, ...) if runnable.respond_to? name

        super
      end

      # @private
      def respond_to_missing?(name)
        runnable.respond_to?(name) || super
      end
    end
  end
end
