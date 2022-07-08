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
          field :test_count
          field :version
          field :links
          association :suite_options, blueprint: SuiteOption
          association :presets, view: :summary, blueprint: Preset
        end

        view :full do
          include_view :summary
          field :test_groups do |suite, options|
            TestGroup.render_as_hash(suite.groups(options[:suite_options]))
          end
          field :configuration_messages
          field :available_inputs, name: :inputs, extractor: HashValueExtractor, blueprint: Input
        end
      end
    end
  end
end
