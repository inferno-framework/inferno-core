require_relative 'preset'
require_relative 'requirements_filtering_extractor'
require_relative 'requirement_set'
require_relative 'suite_option'
require_relative 'test_group'

module Inferno
  module Web
    module Serializers
      class TestSuite < Serializer
        view :summary do
          identifier :id
          field :title
          field :short_title
          field :description
          field :short_description
          field :input_instructions
          field :version
          field :links
          field :suite_summary

          field :test_count do |suite, options|
            suite.test_count(options[:suite_options])
          end

          field :inputs do |suite, options|
            suite_options = options[:suite_options]
            Input.render_as_hash(suite.available_inputs(suite_options).values)
          end

          association :suite_options, blueprint: SuiteOption
          association :presets, view: :summary, blueprint: Preset
        end

        view :full do
          include_view :summary

          field :test_groups do |suite, options|
            suite_options = options[:suite_options]
            suite_requirement_ids = options[:suite_requirement_ids]
            TestGroup.render_as_hash(suite.groups(suite_options), suite_options:, suite_requirement_ids:)
          end
          field :configuration_messages
          field :requirement_sets, if: :field_present? do |suite, options|
            selected_options = options[:suite_options] || []
            requirement_sets = suite.requirement_sets.select do |requirement_set|
              requirement_set.suite_options.all? { |suite_option| selected_options.include? suite_option }
            end

            RequirementSet.render_as_hash(requirement_sets)
          end
          field :verifies_requirements, if: :field_present?, extractor: RequirementsFilteringExtractor
        end
      end
    end
  end
end
