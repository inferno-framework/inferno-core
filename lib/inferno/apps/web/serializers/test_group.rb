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
        field :test_count
        field :run_as_group?, name: :run_as_group
        field :user_runnable?, name: :user_runnable
        field :optional?, name: :optional

        association :groups, name: :test_groups, blueprint: TestGroup
        association :tests, blueprint: Test
        field :available_input_definitions, name: :inputs, extractor: HashValueExtractor, blueprint: Input
        field :output_definitions, name: :outputs, extractor: HashValueExtractor
      end
    end
  end
end
