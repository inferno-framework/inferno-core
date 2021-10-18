module Inferno
  module Web
    module Serializers
      class TestGroup < Serializer
        identifier :id

        field :title
        field :description
        field :test_count
        field :run_as_group?, name: :run_as_group
        field :user_runnable?, name: :user_runnable

        association :groups, name: :test_groups, blueprint: TestGroup
        association :tests, blueprint: Test
        field :input_definitions, name: :inputs, extractor: HashValueExtractor, blueprint: Input
        field :output_definitions, name: :outputs, extractor: HashValueExtractor
      end
    end
  end
end
