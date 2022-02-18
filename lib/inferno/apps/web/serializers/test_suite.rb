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
          association :presets, view: :summary, blueprint: Preset
        end

        view :full do
          include_view :summary
          association :groups, name: :test_groups, blueprint: TestGroup
          field :configuration_messages
        end
      end
    end
  end
end
