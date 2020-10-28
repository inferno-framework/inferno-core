module Inferno
  module DSL
    # This module handles storing and retrieving requests/responses made by
    # FHIR/HTTP clients
    module RequestStorage
      def self.included(klass)
        klass.extend ClassMethods
      end

      # Returns the FHIR/HTTP requests that have been made in this `Test`
      #
      # @return [Array<Inferno::Entities::Request>]
      def requests
        @requests ||= []
      end

      # Returns the most recent FHIR/HTTP request
      #
      # @return [Inferno::Entities::Request]
      def request
        requests.last
      end

      # Returns the response from the most recent FHIR/HTTP request
      #
      # @return [Hash, nil]
      def response
        request&.response
      end

      # Returns the FHIR resource from the response to the most recent FHIR
      # request
      #
      # @return [FHIR::Model, nil]
      def resource
        request&.resource
      end

      # TODO: do a check in the test runner
      def named_request(name)
        requests.find { |request| request.name == name.to_sym }
      end

      # @api private
      def store_request(direction, name = nil, &block)
        response = block.call

        request =
          if response.is_a? FHIR::ClientReply
            Entities::Request.from_fhir_client_reply(
              response, direction: direction, name: name, test_session_id: test_session_id
            )
          else
            Entities::Request.from_http_response(
              response, direction: direction, name: name, test_session_id: test_session_id
            )
          end

        requests << request
        request
      end

      # @api private
      def load_named_requests
        requests_repo = Inferno::Repositories::Requests.new
        self.class.named_requests_used.map do |request_name|
          request = requests_repo.find_named_request(test_session_id, request_name)
          raise StandardError, "Unable to find '#{request_name}' request" if request.nil?

          requests << request
        end
      end

      module ClassMethods
        # @api private
        def named_requests_made
          @named_requests_made ||= []
        end

        # @api private
        def named_requests_used
          @named_requests_used ||= []
        end

        # Specify the named requests made by a test
        #
        # @param *names [Symbol] one or more Symbols
        def makes_request(*names)
          named_requests_made.concat(names)
        end

        # Specify the named requests used by a test
        #
        # @param *names [Symbol] one or more Symbols
        def uses_request(*names)
          named_requests_used.concat(names)
        end
      end
    end
  end
end
