module Inferno
  module DSL
    # DSL for configuring FHIR clients
    class FHIRClientBuilder
      attr_accessor :runnable

      # @api private
      def build(runnable, block)
        self.runnable = runnable
        instance_exec(self, &block)

        FHIR::Client.new(url).tap do |client|
          client.additional_headers = headers if headers
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
