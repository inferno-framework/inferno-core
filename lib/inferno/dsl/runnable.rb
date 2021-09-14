require_relative 'configurable'
require_relative 'resume_test_route'
require_relative '../utils/markdown_formatter'

module Inferno
  module DSL
    # This module contains the DSL for defining child entities in the test
    # definition framework.
    module Runnable
      attr_accessor :parent

      include Inferno::Utils::MarkdownFormatter

      # When a class (e.g. TestSuite/TestGroup) uses this module, set it up
      # so that subclassing it works correctly.
      # - add the subclass to the relevant repository when it is created
      # - copy the class instance variables from the superclass
      # - add a hook to the subclass so that its subclasses do the same
      # @api private
      def self.extended(extending_class)
        super
        extending_class.extend Configurable

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
      # variables need to be copied. Any child Runnable classes will themselves
      # need to be subclassed so that their parent can be updated.
      # @api private
      def copy_instance_variables(subclass)
        instance_variables.each do |variable|
          next if [:@id, :@groups, :@tests, :@parent, :@children, :@test_count, :@config].include?(variable)

          subclass.instance_variable_set(variable, instance_variable_get(variable).dup)
        end

        subclass.config(config)

        child_types.each do |child_type|
          new_children = send(child_type).map do |child|
            Class.new(child).tap do |subclass_child|
              subclass_child.parent = subclass
            end
          end

          subclass.instance_variable_set(:"@#{child_type}", new_children)
          subclass.children.concat(new_children)
        end
      end

      # @api private
      def add_self_to_repository
        repository.insert(self)
      end

      # An instance of the repository for the class using this module
      def repository
        nil
      end

      # This method defines a child entity. Classes using this module should
      # alias the method name they wish to use to define child entities to this
      # method.
      # @api private
      def define_child(*args, &block)
        hash_args = process_args(args)

        klass = create_child_class(hash_args)

        klass.parent = self

        child_metadata[:collection] << klass
        children << klass

        configure_child_class(klass, hash_args)

        handle_child_definition_block(klass, &block)

        klass.add_self_to_repository

        klass
      end

      # @api private
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

      # @api private
      def child_metadata(metadata = nil)
        @child_metadata = metadata if metadata
        @child_metadata
      end

      # @api private
      def create_child_class(hash_args)
        superclass_id = hash_args.delete :from

        return Class.new(child_metadata[:class]) if superclass_id.blank?

        superclass = child_metadata[:repo].find(superclass_id)

        raise Exceptions::ParentNotLoadedException.new(child_metadata[:class], superclass_id) unless superclass

        Class.new(superclass)
      end

      # @api private
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

        hash_args.each do |key, value|
          klass.send(key, *value)
        end

        klass.children.each do |child_class|
          klass.configure_child_class(child_class, {})
          child_class.add_self_to_repository
        end
      end

      # @api private
      def handle_child_definition_block(klass, &block)
        klass.class_eval(&block) if block_given?
      end

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

      def title(new_title = nil)
        return @title if new_title.nil?

        @title = new_title
      end

      def description(new_description = nil)
        return @description if new_description.nil?

        @description = format_markdown(new_description)
      end

      # Define inputs
      #
      # @param identifier [Symbol] identifier for the input
      # @param other_identifiers [Symbol] array of symbols if specifying multiple inputs
      # @param input_definition [Hash] options for input such as type, description, or title
      # @option input_definition [String] :title Human readable title for input
      # @option input_definition [String] :description Description for the input
      # @option input_definition [String] :type text | textarea
      # @option input_definition [String] :default The default value for the input
      # @option input_definition [Boolean] :optional Set to true to not require input for test execution
      # @return [void]
      # @example
      #   input :patientid, title: 'Patient ID', description: 'The ID of the patient being searched for',
      #                     default: 'default_patient_id'
      # @example
      #   input :textarea, title: 'Textarea Input Example', type: 'textarea', optional: true
      def input(identifier, *other_identifiers, **input_definition)
        if other_identifiers.present?
          [identifier, *other_identifiers].compact.each do |input_identifier|
            inputs << input_identifier
            config.add_input(input_identifier)
          end
        else
          inputs << identifier
          config.add_input(identifier, input_definition)
        end
      end

      # Define outputs
      #
      # @param output_lists [Symbol]
      # @return [void]
      # @example
      #   output :patient_id, :bearer_token
      def output(*output_list)
        output_list.each do |output_identifier|
          outputs << output_identifier
          config.add_output(output_identifier)
        end
      end

      # @api private
      def default_id
        to_s
      end

      # @api private
      def inputs
        @inputs ||= []
      end

      def input_definitions
        config.inputs.slice(*inputs)
      end

      def output_definitions
        config.outputs.slice(*outputs)
      end

      # @api private
      def outputs
        @outputs ||= []
      end

      # @api private
      def child_types
        return [] if ancestors.include? Inferno::Entities::Test
        return [:groups] if ancestors.include? Inferno::Entities::TestSuite

        [:groups, :tests]
      end

      # @api private
      def children
        @children ||= []
      end

      def validator_url(url = nil)
        return @validator_url ||= parent&.validator_url if url.nil?

        @validator_url = url
      end

      # @api private
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
      #   {Inferno::DSL::Request} object with the information for the incoming
      #   request.
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

      def test_count
        @test_count ||= children&.reduce(0) { |sum, child| sum + child.test_count } || 0
      end

      def required_inputs(prior_outputs = [])
        required_inputs = inputs.select do |input|
          !input_definitions[input][:optional] && !prior_outputs.include?(input)
        end
        children_required_inputs = children.flat_map { |child| child.required_inputs(prior_outputs) }
        prior_outputs.concat(outputs)
        (required_inputs + children_required_inputs).flatten.uniq
      end

      def missing_inputs(submitted_inputs)
        submitted_inputs = [] if submitted_inputs.nil?

        required_inputs.map(&:to_s) - submitted_inputs.map { |input| input[:name] }
      end

      def user_runnable?
        @user_runnable ||= parent.nil? ||
                           !parent.respond_to?(:user_runnable?) ||
                           !parent.respond_to?(:run_as_group?) ||
                           (parent.user_runnable? && !parent.run_as_group?)
      end
    end
  end
end
