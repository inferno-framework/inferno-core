module Inferno
  module Web
    module Serializers
      class Test < Serializer
        identifier :id
        field :title
        field :input_definitions, name: :inputs, extractor: HashValueExtractor, blueprint: Input
        field :output_definitions, name: :outputs, extractor: HashValueExtractor
        field :description
      end
    end
  end
end
