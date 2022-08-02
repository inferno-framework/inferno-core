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

          field :test_count do |suite, options|
            suite_options = options[:suite_options]
            suite.groups(suite_options).inject(0) do |total_test_count, group|
              total_test_count + (group.test_count(suite_options))
            end
          end

          association :suite_options, blueprint: SuiteOption
          association :presets, view: :summary, blueprint: Preset
        end

        view :full do
          include_view :summary
          field :test_groups do |suite, options|
            suite_options = options[:suite_options]
            TestGroup.render_as_hash(suite.groups(suite_options), suite_options: suite_options)
          end
          field :configuration_messages
          field :inputs do |suite, options|
            suite_options = options[:suite_options]
            Input.render_as_hash(suite.available_inputs(suite_options).values)
          end
        end
      end
    end
  end
end
