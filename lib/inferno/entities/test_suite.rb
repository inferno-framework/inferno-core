require_relative 'test_group'
require_relative '../dsl/runnable'
require_relative '../dsl/suite_option'
require_relative '../dsl/messages'
require_relative '../dsl/links'
require_relative '../repositories/test_groups'
require_relative '../repositories/test_suites'
require_relative '../result_collection'

module Inferno
  module Entities
    # A `TestSuite` represents a packaged group of tests, usually for a
    # single Implementation Guide
    class TestSuite
      extend DSL::Runnable
      extend DSL::Links
      extend DSL::FHIRClient::ClassMethods
      extend DSL::HTTPClient::ClassMethods
      include DSL::FHIRValidation
      include DSL::FHIRResourceValidation
      include DSL::FhirpathEvaluation
      include DSL::Results
      include DSL::Assertions
      include DSL::Messages

      def_delegators 'self.class', :block

      attr_accessor :result_message, :results

      # @private
      def initialize
        @results = Inferno::ResultCollection.new
      end

      class << self
        extend Forwardable

        def_delegator :default_group, :test

        # @private
        def default_group
          return @default_group if @default_group

          @default_group = Class.new(TestGroup)
          all_children << @default_group
          @default_group
        end

        # @private
        def repository
          Inferno::Repositories::TestSuites.new
        end

        # Get this suite's child groups, filtered by suite options, if provided.
        #
        # @param options [Array<Inferno::DSL::SuiteOption>]
        #
        # @return [Array<Inferno::Entities::TestGroup>]
        def groups(options = nil)
          children(options).select { |child| child < Inferno::Entities::TestGroup }
        end

        # Methods to configure Inferno::DSL::Runnable

        # Add a child group
        # @return [void]
        def group(...)
          child_metadata(group_metadata)
          define_child(...)
        end

        # @private
        def group_metadata
          {
            class: TestGroup,
            repo: Inferno::Repositories::TestGroups.new
          }
        end

        # @private
        def reference_hash
          {
            test_suite_id: id
          }
        end

        # Set/get the version of this test suite. Defaults to the TestKit
        # version.
        #
        # @param version [String]
        #
        # @return [String, nil]
        def version(version = nil)
          @version = version if version.present?

          @version || test_kit&.version
        end

        # @private
        def configuration_messages(new_messages = nil, force_recheck: false)
          return @configuration_messages = new_messages unless new_messages.nil?

          @configuration_messages =
            if force_recheck
              @check_configuration_block ? @check_configuration_block.call : []
            else
              @configuration_messages || (@check_configuration_block ? @check_configuration_block.call : [])
            end
        end

        # Provide a block which will verify any configuration needed for this
        # test suite to operate properly.
        #
        # @yieldreturn [Array<Hash>] An array of message hashes containing the
        #   keys `:type` and `:message`. Type options are `info`, `warning`, and
        #   `error`.
        # @return [void]
        def check_configuration(&block)
          @check_configuration_block = lambda do
            block.call&.each do |configuration_message|
              case configuration_message[:type]
              when 'warning'
                Application[:logger].warn(configuration_message[:message])
              when 'error'
                Application[:logger].error(configuration_message[:message])
              end
            end
          end
        end

        # @private
        def presets
          @presets ||= Repositories::Presets.new.presets_for_suite(id)
        end

        # Define an option for this suite. Options are used to define suite-wide
        # configuration which is selected by a user at the start of a test
        # session. These options can be used to change what tests/groups are run
        # or behavior within particular tests.
        #
        # @param identifier [Symbol, String] The identifier which will be used
        #   to refer to this option
        # @option option_params [String] :title Title which will be displayed in
        #   the UI
        # @option option_params [Array<Hash>] :list_options The list of possible
        #   values for this option. Each hash needs to have a `label:` and a
        #   `value:` entry which are Strings.
        #
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
        def suite_option(identifier, **option_params)
          suite_options << DSL::SuiteOption.new(option_params.merge(id: identifier))
        end

        # @return [Array<Inferno::DSL::SuiteOption>] The options defined for
        #   this suite
        def suite_options
          @suite_options ||= []
        end

        # Set/get a description which for this test suite which will be
        # displayed in the UI.
        #
        # @param suite_summary [String]
        #
        # @return [String, nil]
        def suite_summary(suite_summary = nil)
          return @suite_summary if suite_summary.nil?

          @suite_summary = format_markdown(suite_summary)
        end

        # Get the TestKit this suite belongs to
        #
        # @return [Inferno::Entities::TestKit]
        def test_kit
          return @test_kit if @test_kit

          module_name = name

          while module_name.present? && @test_kit.nil?
            module_name = module_name.deconstantize

            next unless const_defined?("#{module_name}::Metadata")

            @test_kit = const_get("#{module_name}::Metadata")
          end

          @test_kit
        end
      end
    end
  end

  TestSuite = Entities::TestSuite
end
