require_relative '../dsl'
require_relative '../repositories/test_groups'
require_relative '../dsl/result_collection'

module Inferno
  module Entities
    class TestGroup
      extend Forwardable
      extend DSL::FHIRClient::ClassMethods
      extend DSL::HTTPClient::ClassMethods
      extend DSL::Runnable
      include DSL::FHIRValidation
      include DSL::FhirpathEvaluation
      include DSL::Results
      include DSL::Assertions
      include DSL::Messages

      def_delegators 'self.class', :title, :id, :block, :groups, :inputs, :outputs, :tests

      attr_accessor :result_message, :results

      # @private
      def initialize
        @results = Inferno::DSL::ResultCollection.new
      end

      # @private
      def method_missing(name, ...)
        parent_instance = self.class.parent&.new
        if parent_instance.respond_to?(name)
          parent_instance.send(name, ...)
        else
          super
        end
      end

      # @private
      def respond_to_missing?(name, _include_private = false)
        self.class.parent&.new&.respond_to?(name)
      end

      class << self
        # @private
        def repository
          Inferno::Repositories::TestGroups.new
        end

        # Get this group's child groups, filtered by suite options, if provided.
        #
        # @param options [Array<Inferno::DSL::SuiteOption>]
        #
        # @return [Array<Inferno::Entities::TestGroup>]
        def groups(options = nil)
          children(options).select { |child| child < Inferno::Entities::TestGroup }
        end

        # Get this group's child tests, filtered by suite options, if provided.
        #
        # @param options [Array<Inferno::DSL::SuiteOption>]
        #
        # @return [Array<Inferno::Entities::Test>]
        def tests(options = nil)
          children(options).select { |child| child < Inferno::Entities::Test }
        end

        # Methods to configure Inferno::DSL::Runnable

        # Add a child group
        # @return [void]
        def group(...)
          child_metadata(group_metadata)
          define_child(...)
        end

        # Add a test
        # @return [void]
        def test(...)
          child_metadata(test_metadata)
          define_child(...)
        end

        # @private
        def group_metadata
          {
            class: TestGroup,
            repo: repository
          }
        end

        # @private
        def test_metadata
          {
            class: Test,
            repo: Inferno::Repositories::Tests.new
          }
        end

        # @return [String] A short numeric id which is displayed in the UI
        def short_id(new_short_id = nil)
          return @short_id = new_short_id if new_short_id

          @short_id ||= begin
            prefix = parent.respond_to?(:short_id) ? "#{parent.short_id}." : ''
            suffix = parent ? (parent.groups.find_index(self) + 1).to_s : 'X'
            "#{prefix}#{suffix}"
          end
        end

        # @private
        def default_id
          return name if name.present?

          suffix = parent ? (parent.groups.find_index(self) + 1).to_s.rjust(2, '0') : SecureRandom.uuid
          "Group#{suffix}"
        end

        # @private
        def reference_hash
          {
            test_group_id: id
          }
        end

        # When true, this group's children can not be run individually in the
        # UI, and this group must be run as a group.
        #
        # @param value [Boolean]
        # @return [void]
        def run_as_group(value = true) # rubocop:disable Style/OptionalBooleanParameter
          @run_as_group = value
        end

        # @return [Boolean]
        def run_as_group?
          @run_as_group || false
        end
      end
    end
  end

  TestGroup = Entities::TestGroup
end
