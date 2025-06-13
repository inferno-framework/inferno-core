require_relative 'configurable'
require_relative 'input_output_handling'
require_relative 'resume_test_route'
require_relative '../exceptions'
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
        end
      end

      # Class instance variables are used to hold the metadata for Runnable
      # classes. When inheriting from a Runnable class, these class instance
      # variables need to be copied. Some instance variables should not be
      # copied, and will need to be repopulated from scratch on the new class.
      # Any child Runnable classes will themselves need to be subclassed so that
      # their parent can be updated.
      # @private
      VARIABLES_NOT_TO_COPY = [
        :@id, # New runnable will have a different id
        :@database_id, # New runnable will have a different database_id
        :@parent, # New runnable unlikely to have the same parent
        :@all_children, # New subclasses have to be made for each child
        :@test_count, # Needs to be recalculated
        :@config, # Needs to be set by calling .config, which does extra work
        :@available_inputs, # Needs to be recalculated
        :@children_available_inputs # Needs to be recalculated
      ].freeze

      # Recursively duplicate arrays/hashes to prevent them from being shared
      # across different runnables
      def deep_dup(value)
        if value.is_a? Array
          value.map { |element| deep_dup(element) }
        elsif value.is_a? Hash
          value.transform_values { |element| deep_dup(element) }
        else
          value.dup
        end
      end

      # @private
      def copy_instance_variables(subclass)
        instance_variables
          .reject { |variable| VARIABLES_NOT_TO_COPY.include? variable }
          .each { |variable| subclass.instance_variable_set(variable, deep_dup(instance_variable_get(variable))) }

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

      # @private
      def remove_self_from_repository
        repository.remove(self)
        children.each(&:remove_self_from_repository)
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
      def define_child(*args, &)
        hash_args = process_args(args)

        klass = create_child_class(hash_args)

        klass.parent = self

        all_children << klass

        configure_child_class(klass, hash_args)

        handle_child_definition_block(klass, &)

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
      def handle_child_definition_block(klass, &)
        klass.class_eval(&) if block_given?
      end

      # Set/Get a runnable's id
      #
      # @param new_id [String,Symbol]
      # @return [String,Symbol] the id
      def id(new_id = nil)
        return @id if new_id.nil? && @id.present?

        prefix = parent ? "#{parent.id}-" : ''
        @base_id = new_id || @base_id || default_id
        @id = "#{prefix}#{@base_id}"

        if @id.length > 255
          hash = Digest::SHA1.hexdigest(@id)[0...10]
          @database_id = "#{@id[0...244]}-#{hash}"
        end

        @id
      end

      def database_id
        @database_id ||= id
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

      # Set/Get the IDs of requirements verified by this runnable
      # Set with [] to clear the list
      #
      # @param requirements [Array<String>]
      # @return [Array<String>] the requirement IDs
      def verifies_requirements(*requirement_ids)
        if requirement_ids.empty?
          @requirement_ids || []
        elsif requirement_ids == [[]]
          @requirement_ids = []
        else
          @requirement_ids = requirement_ids
        end
      end

      # Mark as optional. Tests are required by default.
      #
      # @param optional [Boolean]
      # @return [void]
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

      # Set/Get the block that is executed when a runnable is run
      #
      # @param block [Proc]
      # @return [Proc] the block that is executed when a runnable is run
      def block(&block)
        return @block unless block_given?

        @block = block
      end

      alias run block

      # @private
      def all_children
        @all_children ||= []
      end

      # @private
      def all_descendants
        children.flat_map { |child| [child] + child.all_descendants }
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
      #   resume_test_route :get, '/launch', tags: ['launch'] do
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
      # @param tags [Array<String>] a list of tags to assign to the request
      # @param result [String] the result for the waiting test. Must be one of:
      #   'pass', 'fail', 'skip', 'omit', 'cancel'
      # @yield This method takes a block which must return the identifier
      #   defined when a test was set to wait for the test run that hit this
      #   route. The block has access to the `request` method which returns a
      #   {Inferno::Entities::Request} object with the information for the
      #   incoming request.
      # @return [void]
      def resume_test_route(method, path, tags: [], result: 'pass', &block)
        route_class = Class.new(ResumeTestRoute) do |klass|
          klass.singleton_class.instance_variable_set(:@test_run_identifier_block, block)
          klass.singleton_class.instance_variable_set(:@tags, tags)
          klass.singleton_class.instance_variable_set(:@result, result)
        end

        route(method, path, route_class)
      end

      # Create an endpoint to receive incoming requests during a Test Run.
      #
      # @see Inferno::DSL::SuiteEndpoint
      # @example
      #  suite_endpoint :post, '/my_suite_endpoint', MySuiteEndpoint
      # @param method [Symbol] the HTTP request type (:get, :post, etc.) for the
      #   incoming request
      # @param path [String] the path for this request. The route will be served
      #   with a prefix of `/custom/TEST_SUITE_ID` to prevent path conflicts.
      #   [Any of the path options available in Hanami
      #   Router](https://github.com/hanami/router/tree/f41001d4c3ee9e2d2c7bb142f74b43f8e1d3a265#a-beautiful-dsl)
      #   can be used here.
      # @param [Class] a subclass of Inferno::DSL::SuiteEndpoint
      # @return [void]
      def suite_endpoint(method, path, endpoint_class)
        route(method, path, endpoint_class)
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
      # @return [void]
      def route(method, path, handler)
        Inferno.routes << { method:, path:, handler:, suite: }
      end

      # @private
      def test_count(selected_suite_options = [])
        @test_counts ||= {}

        options_json = selected_suite_options.to_json

        return @test_counts[options_json] if @test_counts[options_json]

        @test_counts[options_json] =
          children(selected_suite_options)
            &.reduce(0) { |sum, child| sum + child.test_count(selected_suite_options) } || 0
      end

      # @private
      def user_runnable?
        @user_runnable ||= parent.nil? ||
                           !parent.respond_to?(:run_as_group?) ||
                           (parent.user_runnable? && !parent.run_as_group?)
      end

      # Set/get suite options required for this runnable to be executed.
      #
      # @param suite_option_requirements [Hash]
      # @example
      #   suite_option :ig_version,
      #               list_options: [
      #                 {
      #                   label: 'IG v1',
      #                   value: 'ig_v1'
      #                 },
      #                 {
      #                   label: 'IG v2',
      #                   value: 'ig_v2'
      #                 }
      #               ]
      #
      #   group from: :ig_v1_group,
      #         required_suite_options: { ig_version: 'ig_v1' }
      #
      #   group from: :ig_v2_group do
      #     required_suite_options ig_version: 'ig_v2'
      #   end
      # @return [void]
      def required_suite_options(suite_option_requirements)
        @suite_option_requirements =
          suite_option_requirements.map do |key, value|
            DSL::SuiteOption.new(id: key, value:)
          end
      end

      # Move a child test/group to a new position within the children list.
      #
      # @param child_id [Symbol, String] The ID of the child to be moved.
      # @param new_index [Integer] The new position for the child.
      # @example
      #   reorder(:test3, 1) # Moves `test3` to index 1
      #
      def reorder(child_id, new_index)
        index = children.find_index { |child| child.id.to_s.end_with? child_id.to_s }
        raise Exceptions::RunnableChildNotFoundException.new(child_id, self) unless index

        unless new_index.between?(0, children.length - 1)
          Inferno::Application[:logger].error <<~ERROR
            Error trying to reorder children for #{self}:
            new_index #{new_index} for #{child_id} is out of range
            (must be between 0 and #{children.length - 1})
          ERROR
          return
        end

        child = children.delete_at(index)
        children.insert(new_index, child)
      end

      # Replace a child test/group
      #
      # @param id_to_replace [Symbol, String] The ID of the child to be replaced.
      # @param replacement_id [Symbol, String] The global ID of the group/test that will take the
      #   place of the child being replaced.
      # @yield [Inferno::TestGroup, Inferno::Test] Optional block executed in the
      #    context of the replacement child for additional configuration.
      # @example
      #   replace :test2, :test4 do
      #     id :new_test_id
      #     config(...)
      #   end
      def replace(id_to_replace, replacement_id, &)
        index = children.find_index { |child| child.id.to_s.end_with? id_to_replace.to_s }
        raise Exceptions::RunnableChildNotFoundException.new(id_to_replace, self) unless index

        if children[index] < Inferno::TestGroup
          group(from: replacement_id, &)
        else
          test(from: replacement_id, &)
        end

        remove(id_to_replace)
        children.insert(index, children.pop)
      end

      # Remove a child test/group
      #
      # @param id_to_remove [Symbol, String]
      # @example
      #   test from: :test1
      #   test from: :test2
      #   test from: :test3
      #
      #   remove :test2
      def remove(id_to_remove)
        removed = children.select { |child| child.id.to_s.end_with? id_to_remove.to_s }
        children.reject! { |child| child.id.to_s.end_with? id_to_remove.to_s }
        removed.each(&:remove_self_from_repository)
      end

      # @private
      def children(selected_suite_options = [])
        return all_children if selected_suite_options.blank?

        all_children.select do |child|
          requirements = child.suite_option_requirements

          if requirements.blank?
            true
          else
            requirements.all? { |requirement| selected_suite_options.include? requirement }
          end
        end
      end

      # @private
      def all_verified_requirements(suite_options = [])
        verifies_requirements + children(suite_options).flat_map do |child|
          child.all_verified_requirements(suite_options)
        end.uniq
      end

      # @private
      def inspect
        non_dynamic_ancestor = ancestors.find { |ancestor| !ancestor.to_s.start_with? '#' }
        "#<#{non_dynamic_ancestor}".tap do |inspect_string|
          inspect_string.concat(" @id=#{id.inspect},")
          inspect_string.concat(" @short_id=#{short_id.inspect},") if respond_to? :short_id
          inspect_string.concat(" @title=#{title.inspect}")
          inspect_string.concat('>')
        end
      end
    end
  end
end
