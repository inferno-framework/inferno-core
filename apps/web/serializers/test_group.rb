module Inferno
  module Web
    module Serializers
      class TestGroup < Serializer
        identifier :id

        # TODO: fill out test group
        field :title
        field :description
        # field :run_as_group

        association :groups, name: :test_groups, blueprint: TestGroup
        association :tests, blueprint: Test
        field :inputs do |group, _options|
          group.inputs.map { |input| { name: input } }
        end
        field :outputs do |group, _options|
          group.outputs.map { |input| { name: input } }
        end
      end
    end
  end
end
