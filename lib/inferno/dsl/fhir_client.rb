require_relative 'request_storage'

module Inferno
  module DSL
    # This module contains the FHIR DSL available to test writers.
    #
    # @example
    #   class MyTestGroup < Inferno::TestGroup
    #     # create a "default" client for a group
    #     fhir_client do
    #       url 'https://example.com/fhir'
    #     end
    #
    #     # create a named client for a group
    #     fhir_client :with_custom_header do
    #       url 'https://example.com/fhir'
    #       headers { 'X-my-custom-header': 'ABC123' }
    #     end
    #
    #     test :some_test do
    #       run do
    #         # uses the default client
    #         fhir_read('Patient', 5)
    #
    #         # uses a named client
    #         fhir_read('Patient', 5, client: :with_custom_header)
    #
    #         request  # the most recent request
    #         response # the most recent response
    #         resource # the resource from the most recent response
    #         requests # all of the requests which have been made in this test
    #       end
    #     end
    #   end
    # @see Inferno::FHIRClientBuilder Documentation for the client
    #   configuration DSL
    module FHIRClient
      # @api private
      def self.included(klass)
        klass.extend ClassMethods
        klass.extend Forwardable
        klass.include RequestStorage

        klass.def_delegators 'self.class', :profile_url, :validator_url
      end

      # Return a previously defined FHIR client
      #
      # @param client [Symbol] the name of the client
      # @return [FHIR::Client]
      # @see Inferno::FHIRClientBuilder
      def fhir_client(client = :default)
        fhir_clients[client] ||=
          FHIRClientBuilder.new.build(self, self.class.fhir_client_definitions[client])
      end

      # @api private
      def fhir_clients
        @fhir_clients ||= {}
      end

      # Perform a FHIR operation
      #
      # @note This is a placeholder method until the FHIR::Client supports
      #   general operations
      #
      # @param path [String]
      # @param body [FHIR::Parameters]
      # @param client [Symbol]
      # @param name [Symbol] Name for this request to allow it to be used by
      #   other tests
      # @option options [Hash]  Input headers here - headers are optional and
      #   must be entered as the last piece of input to this method
      # @return [Inferno::Entities::Request]
      def fhir_operation(path, body: nil, client: :default, name: nil, **options)
        store_request('outgoing', name) do
          headers = fhir_client(client).fhir_headers
          headers.merge!('Content-Type' => 'application/fhir+json') if body.present?
          headers.merge!(options[:headers]) if options[:headers].present?
          fhir_client(client).send(:post, path, body, headers)
        end
      end

      # Fetch the capability statement.
      #
      # @param client [Symbol]
      # @param name [Symbol] Name for this request to allow it to be used by
      #   other tests
      # @param _options [Hash] TODO
      # @return [Inferno::Entities::Request]
      def fhir_get_capability_statement(client: :default, name: nil, **_options)
        store_request('outgoing', name) do
          fhir_client(client).conformance_statement
          fhir_client(client).reply
        end
      end

      # Perform a FHIR read interaction.
      #
      # @param resource_type [String, Symbol, Class]
      # @param id [String]
      # @param client [Symbol]
      # @param name [Symbol] Name for this request to allow it to be used by
      #   other tests
      # @param _options [Hash] TODO
      # @return [Inferno::Entities::Request]
      def fhir_read(resource_type, id, client: :default, name: nil, **_options)
        store_request('outgoing', name) do
          fhir_client(client).read(fhir_class_from_resource_type(resource_type), id)
        end
      end

      # Perform a FHIR search interaction.
      #
      # @param resource_type [String, Symbol, Class]
      # @param client [Symbol]
      # @param params [Hash] the search params
      # @param name [Symbol] Name for this request to allow it to be used by
      #   other tests
      # @param _options [Hash] TODO
      # @return [Inferno::Entities::Request]
      def fhir_search(resource_type, client: :default, params: {}, name: nil, **_options)
        store_request('outgoing', name) do
          fhir_client(client)
            .search(fhir_class_from_resource_type(resource_type), search: { parameters: params })
        end
      end

      # Perform a FHIR delete interaction.
      #
      # @param resource_type [String, Symbol, Class]
      # @param id [String]
      # @param client [Symbol]
      # @param name [Symbol] Name for this request to allow it to be used by
      #   other tests
      # @param _options [Hash] TODO
      # @return [Inferno::Entities::Request]
      def fhir_delete(resource_type, id = nil, client: :default, name: nil, **_options)
        store_request('outgoing', name) do
          fhir_client(client).destroy(fhir_class_from_resource_type(resource_type), id, options) 
        end
      end 

      # @todo Make this a FHIR class method? Something like
      #   FHIR.class_for(resource_type)
      # @api private
      def fhir_class_from_resource_type(resource_type)
        FHIR.const_get(resource_type.to_s.camelize)
      end

      module ClassMethods
        # @api private
        def fhir_client_definitions
          @fhir_client_definitions ||= {}
        end

        # Define a FHIR client to be used by a Runnable.
        #
        # @param name [Symbol] a name used to reference this particular client
        # @param block a block to configure the client
        # @see Inferno::FHIRClientBuilder Documentation for the client
        #   configuration DSL
        def fhir_client(name = :default, &block)
          fhir_client_definitions[name] = block
        end
      end
    end
  end
end
