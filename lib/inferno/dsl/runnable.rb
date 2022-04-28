require_relative 'configurable'
require_relative 'input_output_handling'
require_relative 'resume_test_route'
require_relative '../utils/markdown_formatter'

module Inferno
  module DSL
    # This module contains the DSL for defining child entities in the test
    # definition framework.
    module Runnable
      attr_accessor :parent
      attr_reader :suite_option_requirements

      include Inferno::Utils::MarkdownFormatter

      # When a class (e.g. TestSuite/TestGroup) uses this module, set it up
      # so that subclassing it works correctly.
      # - add the subclass to the relevant repository when it is created
      # - copy the class instance variables from the superclass
      # - add a hook to the subclass so that its subclasses do the same
      # @private
      def self.extended(extending_class)
        super
        extending_class.extend Configurable
        extending_class.extend InputOutputHandling

        extending_class.define_singleton_method(:inherited) do |subclass|
          copy_instance_variables(subclass)

          # Whenever the definition of a Runnable class ends, keep track of the
          # file it came from. Once the Suite loader successfully loads a file,
          # it will add all of the Runnable classes from that file to the
          # appropriate repositories.
          TracePoint.trace(:end) do |trace|
            if trace.self == subclass
              subclass.add_self_to_repository
              trace.disable
            end
          end
        end
      end

      # Class instance variables are used to hold the metadata for Runnable
      # classes. When inheriting from a Runnable class, these class instance
      # variables need to be copied. Some instance variables should not be
      # copied, and will need to be repopulated from scratch on the new class.
      # Any child Runnable classes will themselves need to be subclassed so that
      # their parent can be updated.
      VARIABLES_NOT_TO_COPY = [
        :@id, # New runnable will have a different id
        :@parent, # New runnable unlikely to have the same parent
        :@all_children, # New subclasses have to be made for each child
        :@test_count, # Needs to be recalculated
        :@config, # Needs to be set by calling .config, which does extra work
        :@available_inputs, # Needs to be recalculated
        :@children_available_inputs # Needs to be recalculated
      ].freeze

      # @private
      def copy_instance_variables(subclass)
        instance_variables
          .reject { |variable| VARIABLES_NOT_TO_COPY.include? variable }
          .each { |variable| subclass.instance_variable_set(variable, instance_variable_get(variable).dup) }

        subclass.config(config)

        new_children = all_children.map do |child|
          Class.new(child).tap do |subclass_child|
            subclass_child.parent = subclass
          end
        end

        subclass.instance_variable_set(:@all_children, new_children)
      end

      # @private
      def add_self_to_repository
        repository.insert(self)
      end

      # An instance of the repository for the class using this module
      # @private
      def repository
        nil
      end

      # This method defines a child entity. Classes using this module should
      # alias the method name they wish to use to define child entities to this
      # method.
      # @private
      def define_child(*args, &block)
        hash_args = process_args(args)

        klass = create_child_class(hash_args)

        klass.parent = self

        all_children << klass

        configure_child_class(klass, hash_args)

        handle_child_definition_block(klass, &block)

        klass.add_self_to_repository

        klass
      end

      # @private
      def process_args(args)
        hash_args =
          if args[0].is_a? Hash
            args[0]
          elsif args[1].is_a? Hash
            args[1]
          else
            {}
          end

        hash_args[:title] = args[0] if args[0].is_a? String

        hash_args
      end

      # @private
      def child_metadata(metadata = nil)
        @child_metadata = metadata if metadata
        @child_metadata
      end

      # @private
      def create_child_class(hash_args)
        superclass_id = hash_args.delete :from

        return Class.new(child_metadata[:class]) if superclass_id.blank?

        superclass = child_metadata[:repo].find(superclass_id)

        raise Exceptions::ParentNotLoadedException.new(child_metadata[:class], superclass_id) unless superclass

        Class.new(superclass)
      end

      # @private
      def configure_child_class(klass, hash_args) # rubocop:disable Metrics/CyclomaticComplexity
        inputs.each do |name|
          next if klass.inputs.any? { |klass_input_name| klass_input_name == name }

          klass.input name
        end

        outputs.each do |output_name|
          next if klass.outputs.include? output_name

          klass.output output_name
        end

        new_fhir_client_definitions = klass.instance_variable_get(:@fhir_client_definitions) || {}
        fhir_client_definitions.each do |name, definition|
          next if new_fhir_client_definitions.include? name

          new_fhir_client_definitions[name] = definition.dup
        end
        klass.instance_variable_set(:@fhir_client_definitions, new_fhir_client_definitions)

        new_http_client_definitions = klass.instance_variable_get(:@http_client_definitions) || {}
        http_client_definitions.each do |name, definition|
          next if new_http_client_definitions.include? name

          new_http_client_definitions[name] = definition.dup
        end
        klass.instance_variable_set(:@http_client_definitions, new_http_client_definitions)

        klass.config(config)

        klass.all_children.select!(&:required?) if hash_args.delete(:exclude_optional)

        hash_args.each do |key, value|
          if value.is_a? Array
            klass.send(key, *value)
          else
            klass.send(key, value)
          end
        end

        klass.all_children.each do |child_class|
          klass.configure_child_class(child_class, {})
          child_class.add_self_to_repository
        end
      end

      # @private
      def handle_child_definition_block(klass, &block)
        klass.class_eval(&block) if block_given?
      end

      # Set/Get a runnable's id
      #
      # @param new_id [String,Symbol]
      # @return [String,Symbol] the id
      def id(new_id = nil)
        return @id if new_id.nil? && @id.present?

        prefix =
          if parent
            "#{parent.id}-"
          else
            ''
          end

        @base_id = new_id || @base_id || default_id

        @id = "#{prefix}#{@base_id}"
      end

      # Set/Get a runnable's title
      #
      # @param new_title [String]
      # @return [String] the title
      def title(new_title = nil)
        return @title if new_title.nil?

        @title = new_title
      end

      # Set/Get a runnable's short title
      #
      # @param new_short_title [String]
      # @return [String] the short title
      def short_title(new_short_title = nil)
        return @short_title if new_short_title.nil?

        @short_title = new_short_title
      end

      # Set/Get a runnable's description
      #
      # @param new_description [String]
      # @return [String] the description
      def description(new_description = nil)
        return @description if new_description.nil?

        @description = format_markdown(new_description)
      end

      # Set/Get a runnable's short one-sentence description
      #
      # @param new_short_description [String]
      # @return [String] the one-sentence description
      def short_description(new_short_description = nil)
        return @short_description if new_short_description.nil?

        @short_description = format_markdown(new_short_description)
      end

      # Set/Get a runnable's input instructions
      #
      # @param new_input_instructions [String]
      # @return [String] the input instructions
      def input_instructions(new_input_instructions = nil)
        return @input_instructions if new_input_instructions.nil?

        @input_instructions = format_markdown(new_input_instructions)
      end

      # Mark as optional. Tests are required by default.
      #
      # @param optional [Boolean]
      # @return [void]
      #
      def optional(optional = true) # rubocop:disable Style/OptionalBooleanParameter
        @optional = optional
      end

      # Mark as required
      #
      # Tests are required by default. This method is provided to make an
      # existing optional test required.
      #
      # @param required[Boolean]
      # @return [void]
      def required(required = true) # rubocop:disable Style/OptionalBooleanParameter
        @optional = !required
      end

      # The test or group is optional if true
      #
      # @return [Boolean]
      def optional?
        !!@optional
      end

      # The test or group is required if true
      #
      # @return [Boolean]
      def required?
        !optional?
      end

      # @private
      def default_id
        to_s
      end

      # @private
      def all_children
        @all_children ||= []
      end

      def validator_url(url = nil)
        return @validator_url ||= parent&.validator_url if url.nil?

        @validator_url = url
      end

      # @private
      def suite
        return self if ancestors.include? Inferno::Entities::TestSuite

        parent.suite
      end

      # Create a route which will resume a test run when a request is received
      #
      # @see Inferno::DSL::Results#wait
      # @example
      #   resume_test_route :get, '/launch' do
      #     request.query_parameters['iss']
      #   end
      #
      #   test do
      #     input :issuer
      #     receives_request :launch
      #
      #     run do
      #       wait(
      #         identifier: issuer,
      #         message: "Wating to receive a request with an issuer of #{issuer}"
      #       )
      #     end
      #   end
      #
      # @param method [Symbol] the HTTP request type (:get, :post, etc.) for the
      #   incoming request
      # @param path [String] the path for this request. The route will be served
      #   with a prefix of `/custom/TEST_SUITE_ID` to prevent path conflicts.
      #   [Any of the path options available in Hanami
      #   Router](https://github.com/hanami/router/tree/f41001d4c3ee9e2d2c7bb142f74b43f8e1d3a265#a-beautiful-dsl)
      #   can be used here.
      # @yield This method takes a block which must return the identifier
      #   defined when a test was set to wait for the test run that hit this
      #   route. The block has access to the `request` method which returns a
      #   {Inferno::Entities::Request} object with the information for the
      #   incoming request.
      def resume_test_route(method, path, &block)
        route_class = Class.new(ResumeTestRoute) do
          define_method(:test_run_identifier, &block)
          define_method(:request_name, -> { options[:name] })
        end

        route(method, path, route_class)
      end

      # Create a route to handle a request
      #
      # @param method [Symbol] the HTTP request type (:get, :post, etc.) for the
      #   incoming request. `:all` will accept all HTTP request types.
      # @param path [String] the path for this request. The route will be served
      #   with a prefix of `/custom/TEST_SUITE_ID` to prevent path conflicts.
      #   [Any of the path options available in Hanami
      #   Router](https://github.com/hanami/router/tree/f41001d4c3ee9e2d2c7bb142f74b43f8e1d3a265#a-beautiful-dsl)
      #   can be used here.
      # @param handler [#call] the route handler. This can be any Rack
      #   compatible object (e.g. a `Proc` object, a [Sinatra
      #   app](http://sinatrarb.com/)) as described in the [Hanami Router
      #   documentation.](https://github.com/hanami/router/tree/f41001d4c3ee9e2d2c7bb142f74b43f8e1d3a265#mount-rack-applications)
      def route(method, path, handler)
        Inferno.routes << { method: method, path: path, handler: handler, suite: suite }
      end

      # @private
      # TODO: update to handle suite_options
      def test_count
        @test_count ||= all_children&.reduce(0) { |sum, child| sum + child.test_count } || 0
      end

      # @private
      def user_runnable?
        @user_runnable ||= parent.nil? ||
                           !parent.respond_to?(:run_as_group?) ||
                           (parent.user_runnable? && !parent.run_as_group?)
      end

      def when(suite_option_requirements)
        @suite_option_requirements = suite_option_requirements
      end

      def children(selected_suite_options)
        return all_children if selected_suite_options.blank?

        all_children.select do |child|
          requirements = child.suite_option_requirements || {}

          # requirements are a subset of selected options or equal to selected options
          selected_suite_options >= requirements
        end
      end
    end
  end
end
