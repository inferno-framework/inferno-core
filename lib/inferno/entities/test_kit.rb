require_relative '../repositories/test_kits'
require_relative '../repositories/test_suites'

module Inferno
  module Entities
    # @example
    #
    # module USCoreTestKit
    #   class TestKit < Inferno::Entities::TestKit
    #     id :us_core
    #     title 'US Core Test Kit'
    #     description <<~DESCRIPTION
    #       This is a big markdown description of the test kit.
    #     DESCRIPTION
    #     suite_ids ['us_core_v311', 'us_core_v400', 'us_core_v501', 'us_core_v610']
    #     tags ['SMART App Launch', 'US Core']
    #     last_updated '2024-03-07'
    #     version '0.6.4'
    #     maturity 'High'
    #     authors ['Author One', 'Author Two']
    #     repo 'https://github.com/inferno-framework/us-core-test-kit'
    #   end
    # end
    class TestKit
      class << self
        def inherited(inheriting_class)
          super
          inheriting_class.define_singleton_method(:inherited) do |subclass|
            copy_instance_variables(subclass)
          end
        end

        def id(new_id = nil)
          return @id if new_id.nil?

          @id = new_id
        end

        def title(new_title = nil)
          return @title if new_title.nil?

          @title = new_title
        end

        def description(new_description = nil)
          return @description if new_description.nil?

          @description = new_description
        end

        def tags(new_tags = nil)
          return @tags if new_tags.nil?

          @tags = new_tags
        end

        def last_updated(new_last_updated = nil)
          return @last_updated if new_last_updated.nil?

          @last_updated = new_last_updated
        end

        def version(new_version = nil)
          return @version if new_version.nil?

          @version = new_version
        end

        def maturity(new_maturity = nil)
          return @maturity if new_maturity.nil?

          @maturity = new_maturity
        end

        def suite_ids(new_ids = nil)
          return @suite_ids || [] if new_ids.nil?

          @suite_ids = new_ids
        end

        def repo(new_repo = nil)
          return @repo if new_repo.nil?

          @repo = new_repo
        end

        def authors(new_authors = nil)
          return @authors if new_authors.nil?

          @authors = new_authors
        end

        # This probably doesn't belong here, but should really be platform-level
        # metadata
        def pin(pinned = nil)
          return @pin if pinned.nil?

          @pin = pinned
        end

        def suites
          return @suites if @suites.present?

          repo = Inferno::Repositories::TestSuites.new
          @suites = suite_ids.map { |id| repo.find(id) }
        end

        def options
          return @options if @options.present?

          @options = suites.each_with_object({}) { |suite, hash| hash[suite.id] = suite.suite_options }
        end

        # @private
        def add_self_to_repository
          repository.insert(self)
        end

        # @private
        def repository
          @repository ||= Inferno::Repositories::TestKits
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
end
