require_relative 'test_group'
require_relative '../dsl/runnable'
require_relative '../repositories/test_groups'
require_relative '../repositories/test_suites'

module Inferno
  module Entities
    # A `TestSuite` represents a packaged group of tests, usually for a
    # single Implementation Guide
    class TestSuite
      extend DSL::Runnable
      extend DSL::FHIRClient::ClassMethods
      extend DSL::HTTPClient::ClassMethods
      include DSL::FHIRValidation

      class << self
        extend Forwardable

        def_delegator :default_group, :test

        def default_group
          return @default_group if @default_group

          @default_group = Class.new(TestGroup)
          all_children << @default_group
          @default_group
        end

        def repository
          Inferno::Repositories::TestSuites.new
        end

        def groups
          all_children.select { |child| child < Inferno::Entities::TestGroup }
        end

        # Methods to configure Inferno::DSL::Runnable

        def group(...)
          child_metadata(group_metadata)
          define_child(...)
        end

        def group_metadata
          {
            class: TestGroup,
            repo: Inferno::Repositories::TestGroups.new
          }
        end

        def reference_hash
          {
            test_suite_id: id
          }
        end

        def version(version = nil)
          return @version if version.nil?

          @version = version
        end

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
        def check_configuration(&block)
          @check_configuration_block = block
        end

        def presets
          @presets ||= Repositories::Presets.new.presets_for_suite(id)
        end

        def suite_option(identifier, **input_params)
          suite_options[identifier] = input_params.merge(id: identifier)
        end

        def suite_options
          @suite_options ||= {}
        end
      end
    end
  end

  TestSuite = Entities::TestSuite
end
