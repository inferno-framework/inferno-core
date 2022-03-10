require_relative 'input'

module Inferno
  module DSL
    # This module contains the DSL for managing runnable configuration.
    module Configurable
      def self.extended(klass)
        klass.extend Forwardable
        klass.def_delegator 'self.class', :config
      end

      def config(new_configuration = {})
        @config ||= Configuration.new

        return @config if new_configuration.blank?

        @config.apply(new_configuration)

        children.each { |child| child.config(new_configuration) }

        @config
      end

      # @private
      class Configuration
        attr_accessor :configuration

        def initialize(configuration = {})
          self.configuration = configuration
        end

        def apply(new_configuration)
          config_to_apply =
            if new_configuration.is_a? Configuration
              new_configuration.configuration
            else
              new_configuration
            end

          self.configuration = configuration.deep_merge(config_to_apply.reject { |key, _| key == :inputs })

          config_to_apply[:inputs]&.each do |identifier, new_input|
            add_input(identifier, new_input.to_hash)
          end
        end

        def options
          configuration[:options] ||= {}
        end

        ### Input Configuration ###

        def inputs
          configuration[:inputs] ||= {}
        end

        def add_input(identifier, new_config = {})
          existing_config = input(identifier)

          if existing_config.nil?
            return inputs[identifier] = Input.new(default_input_params(identifier).merge(new_config))
          end

          inputs[identifier] =
            Input
              .new(existing_config.to_hash)
              .merge(Input.new(new_config))
        end

        def default_input_params(identifier)
          { name: identifier, type: 'text' }
        end

        def input_exists?(identifier)
          inputs.key? identifier
        end

        def input(identifier)
          inputs[identifier]
        end

        def input_name(identifier)
          inputs[identifier]&.name
        end

        def input_type(identifier)
          inputs[identifier]&.type
        end

        ### Output Configuration ###

        def outputs
          configuration[:outputs] ||= {}
        end

        def add_output(identifier, new_config = {})
          existing_config = output_config(identifier) || {}
          outputs[identifier] = default_output_config(identifier).merge(existing_config, new_config)
        end

        def default_output_config(identifier)
          { name: identifier, type: 'text' }
        end

        def output_config_exists?(identifier)
          outputs.key? identifier
        end

        def output_config(identifier)
          outputs[identifier]
        end

        def output_name(identifier)
          outputs.dig(identifier, :name) || identifier
        end

        def output_type(identifier)
          outputs.dig(identifier, :type)
        end

        ### Request Configuration ###

        def requests
          configuration[:requests] ||= {}
        end

        def add_request(identifier)
          return if request_config_exists?(identifier)

          requests[identifier] = default_request_config(identifier)
        end

        def default_request_config(identifier)
          { name: identifier }
        end

        def request_config_exists?(identifier)
          requests.key? identifier
        end

        def request_config(identifier)
          requests[identifier]
        end

        def request_name(identifier)
          requests.dig(identifier, :name) || identifier
        end
      end
    end
  end
end
