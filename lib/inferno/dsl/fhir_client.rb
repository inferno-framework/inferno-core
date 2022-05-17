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
      # @private
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

      # @private
      def fhir_clients
        @fhir_clients ||= {}
      end

      # @private
      def fhir_error_filter(&block)
        block.call
      rescue SocketError => e
        e.message.include?('Failed to open TCP') ? raise(Exceptions::AssertionException, e.message) : raise(e)
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
      # @param headers [Hash] custom headers for this operation
      # @return [Inferno::Entities::Request]
      def fhir_operation(path, body: nil, client: :default, name: nil, headers: {})
        fhir_error_filter do
          store_request_and_refresh_token(fhir_client(client), name) do
            operation_headers = fhir_client(client).fhir_headers
            operation_headers.merge!('Content-Type' => 'application/fhir+json') if body.present?
            operation_headers.merge!(headers) if headers.present?

            fhir_client(client).send(:post, path, body, operation_headers)
          end
        end
      end

      # Fetch the capability statement.
      #
      # @param client [Symbol]
      # @param name [Symbol] Name for this request to allow it to be used by
      #   other tests
      # @return [Inferno::Entities::Request]
      def fhir_get_capability_statement(client: :default, name: nil)
        fhir_error_filter do
          store_request_and_refresh_token(fhir_client(client), name) do
            fhir_client(client).conformance_statement
            fhir_client(client).reply
          end
        end
      end

      # Perform a FHIR read interaction.
      #
      # @param resource_type [String, Symbol, Class]
      # @param id [String]
      # @param client [Symbol]
      # @param name [Symbol] Name for this request to allow it to be used by
      #   other tests
      # @return [Inferno::Entities::Request]
      def fhir_read(resource_type, id, client: :default, name: nil)
        fhir_error_filter do
          store_request_and_refresh_token(fhir_client(client), name) do
            fhir_client(client).read(fhir_class_from_resource_type(resource_type), id)
          end
        end
      end

      # Perform a FHIR search interaction.
      #
      # @param resource_type [String, Symbol, Class]
      # @param client [Symbol]
      # @param params [Hash] the search params
      # @param name [Symbol] Name for this request to allow it to be used by
      #   other tests
      # @param search_method [Symbol] Use `:post` to search via POST
      # @return [Inferno::Entities::Request]
      def fhir_search(resource_type, client: :default, params: {}, name: nil, search_method: :get)
        search =
          if search_method == :post
            { body: params }
          else
            { parameters: params }
          end

        fhir_error_filter do
          store_request_and_refresh_token(fhir_client(client), name) do
            fhir_client(client)
              .search(fhir_class_from_resource_type(resource_type), { search: search })
          end
        end
      end

      # Perform a FHIR delete interaction.
      #
      # @param resource_type [String, Symbol, Class]
      # @param id [String]
      # @param client [Symbol]
      # @param name [Symbol] Name for this request to allow it to be used by
      #   other tests
      # @return [Inferno::Entities::Request]
      def fhir_delete(resource_type, id, client: :default, name: nil)
        fhir_error_filter do
          store_request('outgoing', name) do
            fhir_client(client).destroy(fhir_class_from_resource_type(resource_type), id)
          end
        end
      end

      # @todo Make this a FHIR class method? Something like
      #   FHIR.class_for(resource_type)
      # @api private
      def fhir_class_from_resource_type(resource_type)
        FHIR.const_get(resource_type.to_s.camelize)
      end

      # This method wraps a request to automatically refresh its access token if
      # expired. It's combined with `store_request` so that all of the fhir
      # request methods don't have to be wrapped twice.
      # @api private
      def store_request_and_refresh_token(client, name, &block)
        store_request('outgoing', name) do
          perform_refresh(client) if client.need_to_refresh? && client.able_to_refresh?
          block.call
        end
      end

      # @api private
      def perform_refresh(client)
        credentials = client.oauth_credentials

        post(
          credentials.token_url,
          body: credentials.oauth2_refresh_params,
          headers: credentials.oauth2_refresh_headers
        )

        return if request.status != 200

        credentials.update_from_response_body(request)

        if credentials.name.present?
          Inferno::Repositories::SessionData.new.save(
            name: credentials.name,
            value: credentials,
            type: 'oauth_credentials',
            test_session_id: test_session_id
          )
        end
      rescue StandardError => e
        Inferno::Application[:logger].error "Unable to refresh token: #{e.message}"
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
