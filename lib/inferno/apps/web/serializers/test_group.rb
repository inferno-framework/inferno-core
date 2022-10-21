require_relative 'test'

module Inferno
  module Web
    module Serializers
      class TestGroup < Serializer
        identifier :id

        field :short_id
        field :title
        field :short_title
        field :description
        field :short_description
        field :input_instructions
        field :run_as_group?, name: :run_as_group
        field :user_runnable?, name: :user_runnable
        field :optional?, name: :optional

        field :test_count do |group, options|
          group.test_count(options[:suite_options])
        end
        field :test_groups do |group, options|
          suite_options = options[:suite_options]
          TestGroup.render_as_hash(group.groups(suite_options), suite_options:)
        end
        field :tests do |group, options|
          suite_options = options[:suite_options]
          Test.render_as_hash(group.tests(suite_options), suite_options:)
        end
        field :inputs do |group, options|
          suite_options = options[:suite_options]
          Input.render_as_hash(group.available_inputs(suite_options).values)
        end
        field :output_definitions, name: :outputs, extractor: HashValueExtractor
      end
    end
  end
end
