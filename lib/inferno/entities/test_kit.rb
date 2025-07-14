require_relative '../repositories/test_kits'
require_relative '../repositories/test_suites'

module Inferno
  module Entities
    # @example
    #
    #   module USCoreTestKit
    #     class Metadata < Inferno::Entities::TestKit
    #       id :us_core
    #       title 'US Core Test Kit'
    #       description <<~DESCRIPTION
    #         This is a big markdown description of the test kit.
    #       DESCRIPTION
    #       suite_ids ['us_core_v311', 'us_core_v400', 'us_core_v501', 'us_core_v610']
    #       tags ['SMART App Launch', 'US Core']
    #       last_updated '2024-03-07'
    #       version '0.6.4'
    #       maturity 'High'
    #       authors ['Author One', 'Author Two']
    #       repo 'https://github.com/inferno-framework/us-core-test-kit'
    #     end
    #   end
    class TestKit
      class << self
        def inherited(inheriting_class)
          super
          inheriting_class.define_singleton_method(:inherited) do |subclass|
            copy_instance_variables(subclass)
          end
        end

        # Set/get the id for the test kit
        #
        # @param new_id [Symbol, String]
        # @return [Symbol, String]
        def id(new_id = nil)
          return @id if new_id.nil?

          @id = new_id
        end

        # Set/get the title for the test kit
        #
        # @param new_title [String]
        # @return [String]
        def title(new_title = nil)
          return @title if new_title.nil?

          @title = new_title
        end

        # Set/get the description for the test kit
        #
        # @param new_description [String]
        # @return [String]
        def description(new_description = nil)
          return @description if new_description.nil?

          @description = new_description
        end

        # Set/get the tags for the test kit
        #
        # @param new_tags [Array<String>]
        # @return [Array<String>]
        def tags(new_tags = nil)
          return @tags if new_tags.nil?

          @tags = new_tags
        end

        # Set/get the last updated date for the test kit
        #
        # @param new_last_updated [String]
        # @return [String]
        def last_updated(new_last_updated = nil)
          return @last_updated if new_last_updated.nil?

          @last_updated = new_last_updated
        end

        # Set/get the version for the test kit
        #
        # @param new_version [String]
        # @return [String]
        def version(new_version = nil)
          return @version if new_version.nil?

          @version = new_version
        end

        # Set/get the maturity level for the test kit
        #
        # @param new_maturity [String]
        # @return [String]
        def maturity(new_maturity = nil)
          return @maturity if new_maturity.nil?

          @maturity = new_maturity
        end

        # Set/get the suite ids for the test kit
        #
        # @param new_ids [Array<Symbol,String>]
        # @return [Array<Symbol,String>]
        def suite_ids(new_ids = nil)
          return @suite_ids || [] if new_ids.nil?

          @suite_ids = new_ids
        end

        # Set/get the code repository url for the test kit
        #
        # @param new_repo [String]
        # @return [String]
        def repo(new_repo = nil)
          return @repo if new_repo.nil?

          @repo = new_repo
        end

        # Set/get the list of authors for the test kit
        #
        # @param new_authors [Array<String>]
        # @return [Array<String>]
        def authors(new_authors = nil)
          return @authors if new_authors.nil?

          @authors = new_authors
        end

        # Get the suites whose ids are defined in `suite_ids`
        #
        # @return [Array<Inferno::Entities::TestSuite>]
        def suites
          return @suites if @suites.present?

          repo = Inferno::Repositories::TestSuites.new
          @suites = suite_ids.map { |id| repo.find(id) }
        end

        # Get the options for the suites in the test kit
        #
        # @return [Hash{Symbol,String=>Array<Inferno::DSL::SuiteOption>}]
        def options
          return @options if @options.present?

          @options = suites.each_with_object({}) { |suite, hash| hash[suite.id] = suite.suite_options }
        end

        def contains_test_suite?(test_suite_id)
          suite_ids.map(&:to_sym).include? test_suite_id.to_sym
        end

        def url_fragment
          id.to_s.delete_suffix('_test_kit').tr('_', '-')
        end

        # @private
        def add_self_to_repository
          repository.insert(self)
        end

        # @private
        def repository
          @repository ||= Inferno::Repositories::TestKits.new
        end

        # @private
        def copy_instance_variables
          instance_variables
            .reject { |variable| [:id].include? variable }
            .each { |variable| subclass.instance_variable_set(variable, instance_variable_get(variable).dup) }
        end
      end
    end
  end

  TestKit = Entities::TestKit
end
