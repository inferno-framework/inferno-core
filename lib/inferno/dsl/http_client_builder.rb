module Inferno
  module DSL
    # This module contains the HTTP DSL available to test writers.
    class HTTPClientBuilder
      attr_accessor :runnable

      # @api private
      def build(runnable, block)
        self.runnable = runnable
        instance_exec(self, &block)

        params = { url: url }
        params.merge!(headers: headers) if headers

        Faraday.new(params)
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

      # @api private
      def method_missing(name, *args, &block)
        return runnable.call(name, *args, &block) if runnable.respond_to? name

        super
      end

      # @api private
      def respond_to_missing?(name)
        runnable.respond_to?(name) || super
      end
    end
  end
end
