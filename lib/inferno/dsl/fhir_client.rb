require_relative 'fhir_client_builder'
require_relative 'request_storage'
require_relative 'tcp_exception_handler'

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
    #       headers 'X-my-custom-header': 'ABC123'
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
    # @see Inferno::DSL::FHIRClientBuilder Documentation for the client
    #   configuration DSL
    module FHIRClient
      # @private
      def self.included(klass)
        klass.extend ClassMethods
        klass.extend Forwardable
        klass.include RequestStorage
        klass.include TCPExceptionHandler
      end

      # Return a previously defined FHIR client
      #
      # @param client [Symbol] the name of the client
      # @return [FHIR::Client]
      # @see Inferno::DSL::FHIRClientBuilder
      def fhir_client(client = :default)
        fhir_clients[client] ||=
          FHIRClientBuilder.new.build(self, self.class.fhir_client_definitions[client])
      end

      # @private
      def fhir_clients
        @fhir_clients ||= {}
      end

      # Checks if a parameter can be used in a GET request according FHIR specification
      #
      # @param param [FHIR::Parameters::Parameter] Parameter to be checked
      # @private
      def safe_for_get?(param)
        valid = param.valid? && param.part.empty? && param.resource.nil? # Parameter is valid
        param_val = param.to_hash.except('name') # should contain only one value if it is a valid parameter
        valid && !param_val.empty? && FHIR.primitive?(datatype: param_val.keys[0][5..], value: param_val.values[0])
      end

      # Converts a list of FHIR Parameters into a query string for GET requests
      #
      # @param body [FHIR::Parameters] Must all be primitive if making GET request
      # @private
      def body_to_path(body)
        query_hashes = body.parameter.map do |param|
          if safe_for_get?(param)
            { param.name => param.to_hash.except('name').values[0] }
          else
            # Handle the case of nonprimitive
            Inferno::Application[:logger].error "Cannot use GET request with non-primitive datatype #{param.name}"
            raise ArgumentError, "Cannot use GET request with non-primitive datatype #{param.name}"
          end
        end
        query_hashes.map(&:to_query).join('&')
      end

      # Perform a FHIR operation
      #
      # @note This is a placeholder method until the FHIR::Client supports
      #   general operations.  Note that while both POST and GET methods are allowed,
      #   GET is only allowed when the operation does not affect the servers state.
      #   See https://build.fhir.org/operationdefinition-definitions.html#OperationDefinition.affectsState
      #
      # @param path [String]
      # @param body [FHIR::Parameters] Must all be primitive if making GET request
      # @param client [Symbol]
      # @param name [Symbol] Name for this request to allow it to be used by
      #   other tests
      # @param headers [Hash] custom headers for this operation
      # @param operation_method [Symbol] indicates which request type to use for the operation
      # @return [Inferno::Entities::Request]
      def fhir_operation(path, body: nil, client: :default, name: nil, headers: {}, operation_method: :post)
        store_request_and_refresh_token(fhir_client(client), name) do
          tcp_exception_handler do
            operation_headers = fhir_client(client).fhir_headers
            operation_headers.merge!('Content-Type' => 'application/fhir+json') if body.present?
            operation_headers.merge!(headers) if headers.present?
            case operation_method
            when :post
              fhir_client(client).send(:post, path, body, operation_headers)
            when :get
              path = "#{path}?#{body_to_path(body)}" if body.present?
              fhir_client(client).send(:get, path, operation_headers)
            else
              # Handle the case of non-supported operation_method
              Inferno::Application[:logger].error "Cannot perform #{operation_method} requests, use GET or POST"
              raise ArgumentError, "Cannot perform #{operation_method} requests, use GET or POST"
            end
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
        store_request_and_refresh_token(fhir_client(client), name) do
          tcp_exception_handler do
            fhir_client(client).conformance_statement
            fhir_client(client).reply
          end
        end
      end

      # Perform a FHIR create interaction.
      #
      # @param resource [FHIR::Model]
      # @param client [Symbol]
      # @param name [Symbol] Name for this request to allow it to be used by
      #   other tests
      # @return [Inferno::Entities::Request]
      def fhir_create(resource, client: :default, name: nil)
        store_request_and_refresh_token(fhir_client(client), name) do
          tcp_exception_handler do
            fhir_client(client).create(resource)
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
        store_request_and_refresh_token(fhir_client(client), name) do
          tcp_exception_handler do
            fhir_client(client).read(fhir_class_from_resource_type(resource_type), id)
          end
        end
      end

      # Perform a FHIR vread interaction.
      #
      # @param resource_type [String, Symbol, Class]
      # @param id [String]
      # @param version_id [String]
      # @param client [Symbol]
      # @param name [Symbol] Name for this request to allow it to be used by
      #   other tests
      # @return [Inferno::Entities::Request]
      def fhir_vread(resource_type, id, version_id, client: :default, name: nil)
        store_request_and_refresh_token(fhir_client(client), name) do
          tcp_exception_handler do
            fhir_client(client).vread(fhir_class_from_resource_type(resource_type), id, version_id)
          end
        end
      end

      # Perform a FHIR update interaction.
      #
      # @param resource [FHIR::Model]
      # @param id [String]
      # @param client [Symbol]
      # @param name [Symbol] Name for this request to allow it to be used by
      #   other tests
      # @return [Inferno::Entities::Request]
      def fhir_update(resource, id, client: :default, name: nil)
        store_request_and_refresh_token(fhir_client(client), name) do
          tcp_exception_handler do
            fhir_client(client).update(resource, id)
          end
        end
      end

      # Perform a FHIR patch interaction.
      #
      # @param resource_type [String, Symbol, Class]
      # @param id [String]
      # @param patchset [Array]
      # @param client [Symbol]
      # @param name [Symbol] Name for this request to allow it to be used by
      #   other tests
      # @return [Inferno::Entities::Request]
      def fhir_patch(resource_type, id, patchset, client: :default, name: nil)
        store_request_and_refresh_token(fhir_client(client), name) do
          tcp_exception_handler do
            fhir_client(client).partial_update(fhir_class_from_resource_type(resource_type), id, patchset)
          end
        end
      end

      # Perform a FHIR history interaction.
      #
      # @param resource_type [String, Symbol, Class]
      # @param id [String]
      # @param client [Symbol]
      # @param name [Symbol] Name for this request to allow it to be used by
      #   other tests
      # @return [Inferno::Entities::Request]
      def fhir_history(resource_type = nil, id = nil, client: :default, name: nil)
        store_request_and_refresh_token(fhir_client(client), name) do
          tcp_exception_handler do
            if id
              fhir_client(client).resource_instance_history(fhir_class_from_resource_type(resource_type), id)
            elsif resource_type
              fhir_client(client).resource_history(fhir_class_from_resource_type(resource_type))
            else
              fhir_client(client).all_history
            end
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
      def fhir_search(resource_type = nil, client: :default, params: {}, name: nil, search_method: :get)
        search =
          if search_method == :post
            { body: params }
          else
            { parameters: params }
          end

        store_request_and_refresh_token(fhir_client(client), name) do
          tcp_exception_handler do
            if resource_type
              fhir_client(client)
                .search(fhir_class_from_resource_type(resource_type), { search: })
            else
              fhir_client(client).search_all({ search: })
            end
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
        store_request('outgoing', name) do
          tcp_exception_handler do
            fhir_client(client).destroy(fhir_class_from_resource_type(resource_type), id)
          end
        end
      end

      # Perform a FHIR batch/transaction interaction.
      #
      # @param bundle [FHIR::Bundle] the FHIR batch/transaction Bundle
      # @param client [Symbol]
      # @param name [Symbol] Name for this request to allow it to be used by
      #   other tests
      # @return [Inferno::Entities::Request]
      def fhir_transaction(bundle = nil, client: :default, name: nil)
        store_request('outgoing', name) do
          tcp_exception_handler do
            fhir_client(client).transaction_bundle = bundle if bundle.present?
            fhir_client(client).end_transaction
          end
        end
      end

      # @todo Make this a FHIR class method? Something like
      #   FHIR.class_for(resource_type)
      # @private
      def fhir_class_from_resource_type(resource_type)
        FHIR.const_get(resource_type.to_s.camelize)
      end

      # This method wraps a request to automatically refresh its access token if
      # expired. It's combined with `store_request` so that all of the fhir
      # request methods don't have to be wrapped twice.
      # @private
      def store_request_and_refresh_token(client, name, &block)
        store_request('outgoing', name) do
          perform_refresh(client) if client.need_to_refresh? && client.able_to_refresh?
          block.call
        end
      end

      # @private
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
            test_session_id:
          )
        end
      rescue StandardError => e
        Inferno::Application[:logger].error "Unable to refresh token: #{e.message}"
      end

      module ClassMethods
        # @private
        def fhir_client_definitions
          @fhir_client_definitions ||= {}
        end

        # Define a FHIR client to be used by a Runnable.
        #
        # @param name [Symbol] a name used to reference this particular client
        # @param block a block to configure the client
        # @see Inferno::FHIRClientBuilder Documentation for the client
        #   configuration DSL
        # @return [void]
        def fhir_client(name = :default, &block)
          fhir_client_definitions[name] = block
        end
      end
    end
  end
end
