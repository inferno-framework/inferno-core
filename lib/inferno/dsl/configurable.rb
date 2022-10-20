require_relative '../entities/input'

module Inferno
  module DSL
    # This module contains the DSL for managing runnable configuration. Runnable
    # configuration provides a way to modify test behavior at boot time.
    #
    # The main features enabled by configuration are:
    # - Modifying the properties of a runnable's inputs. This could include
    #   locking a particular input, making a particular input optional/required,
    #   or changing an input's value.
    # - Renaming an input/output/request to avoid name collisions when a test
    #   suite uses the same test multiple times.
    # - Tests can define custom configuration options to enable different
    # - testing behavior.
    #
    # @example
    #   test do
    #     id :json_request_test
    #
    #     input :url
    #     output :response_body
    #     makes_request :json_request
    #
    #     run do
    #       if config.options[:include_content_type]
    #         get url, headers: { 'Content-Type' => 'application/json' }
    #       else
    #         get url
    #       end
    #
    #       assert_response_status(200)
    #       output response_body: request.response_body
    #       assert_valid_json
    #     end
    #   end
    #
    #   group do
    #     test from :json_request_test do
    #       id :json_request_without_content_type
    #
    #       config(
    #         inputs: {
    #           url: { name: :url_without_content_type }
    #         },
    #         outputs: {
    #           response_body: { name: :response_body_without_content_type }
    #         },
    #         requests: {
    #           json_request: { name: :json_request_without_content_type }
    #         }
    #       )
    #     end
    #
    #     test from :json_request_test do
    #       id :json_request_with_content_type
    #
    #       config(
    #         options: {
    #           include_content_type: true
    #         },
    #         inputs: {
    #           url: { name: :url_with_content_type }
    #         },
    #         outputs: {
    #           response_body: { name: :response_body_with_content_type }
    #         },
    #         requests: {
    #           json_request: { name: :json_request_with_content_type }
    #         }
    #       )
    #     end
    #   end
    module Configurable
      def self.extended(klass)
        klass.extend Forwardable
        klass.def_delegator 'self.class', :config
      end

      # Define/update/get the configuration for a runnable. This configuration
      # will be applied to the runnable and all of its children.
      #
      # @param new_configuration [Hash]
      def config(new_configuration = {})
        @config ||= Configuration.new

        return @config if new_configuration.blank?

        @config.apply(new_configuration)

        all_children.each { |child| child.config(new_configuration) }

        @config
      end

      # This class stores a runnable's configuration. It should never be
      # directly instantiated within a test suite. Instead, a runnable's
      # configuration can be modified or retrieved using the `config` method.
      class Configuration
        attr_accessor :configuration

        # @private
        def initialize(configuration = {})
          self.configuration = configuration
        end

        # @private
        def apply(new_configuration)
          config_to_apply =
            if new_configuration.is_a? Configuration
              new_configuration.configuration
            else
              new_configuration
            end

          self.configuration = configuration.deep_merge(config_to_apply.except(:inputs))

          config_to_apply[:inputs]&.each do |identifier, new_input|
            add_input(identifier, new_input.to_hash)
          end
        end

        # The configuration options defined for this runnable.
        #
        # @return [Hash]
        def options
          configuration[:options] ||= {}
        end

        ### Input Configuration ###

        # The input configuration for this runnable.
        #
        # @return [Hash]
        def inputs
          configuration[:inputs] ||= {}
        end

        # @private
        def add_input(identifier, new_config = {})
          existing_config = input(identifier)

          if existing_config.nil?
            return inputs[identifier] = Entities::Input.new(**default_input_params(identifier).merge(new_config))
          end

          inputs[identifier] =
            Entities::Input
              .new(**existing_config.to_hash)
              .merge(Entities::Input.new(**new_config))
        end

        # @private
        def default_input_params(identifier)
          { name: identifier, type: 'text' }
        end

        # @private
        def input_exists?(identifier)
          inputs.key? identifier
        end

        # @private
        def input(identifier)
          inputs[identifier]
        end

        # @private
        def input_name(identifier)
          inputs[identifier]&.name
        end

        # @private
        def input_type(identifier)
          inputs[identifier]&.type
        end

        ### Output Configuration ###

        # The output configuration for this runnable.
        #
        # @return [Hash]
        def outputs
          configuration[:outputs] ||= {}
        end

        # @private
        def add_output(identifier, new_config = {})
          existing_config = output_config(identifier) || {}
          outputs[identifier] = default_output_config(identifier).merge(existing_config, new_config)
        end

        # @private
        def default_output_config(identifier)
          { name: identifier, type: 'text' }
        end

        # @private
        def output_config_exists?(identifier)
          outputs.key? identifier
        end

        # @private
        def output_config(identifier)
          outputs[identifier]
        end

        # @private
        def output_name(identifier)
          outputs.dig(identifier, :name) || identifier
        end

        # @private
        def output_type(identifier)
          outputs.dig(identifier, :type)
        end

        ### Request Configuration ###


        # The request configuration for this runnable.
        #
        # @return [Hash]
        def requests
          configuration[:requests] ||= {}
        end

        # @private
        def add_request(identifier)
          return if request_config_exists?(identifier)

          requests[identifier] = default_request_config(identifier)
        end

        # @private
        def default_request_config(identifier)
          { name: identifier }
        end

        # @private
        def request_config_exists?(identifier)
          requests.key? identifier
        end

        # @private
        def request_config(identifier)
          requests[identifier]
        end

        # @private
        def request_name(identifier)
          requests.dig(identifier, :name) || identifier
        end
      end
    end
  end
end
