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
          children << @default_group
          @default_group
        end

        def repository
          Inferno::Repositories::TestSuites.new
        end

        def groups
          children.select { |child| child < Inferno::Entities::TestGroup }
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

        def find_validator(validator_name)
          validator = fhir_validators[validator_name]

          return validator if validator

          raise Exceptions::ValidatorNotFoundException, validator_name unless validator_name == :default

          fhir_validators[:default] =
            Inferno::DSL::FHIRValidation::Validator.new { |v| v.url default_validator_url }
        end
      end
    end
  end

  TestSuite = Entities::TestSuite
end
