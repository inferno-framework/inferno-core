module Inferno
  module Web
    module Serializers
      class Test < Serializer
        identifier :id
        field :title
        field :input_definitions, name: :inputs, blueprint: Input
        field :output_definitions, name: :outputs
        field :description
      end
    end
  end
end
