module Inferno
  module Web
    module Serializers
      class Test < Serializer
        identifier :id
        field :title
        field :input_definitions, name: :inputs, extractor: HashValueExtractor, blueprint: Input
        field :output_definitions, name: :outputs, extractor: HashValueExtractor
        field :description
        field :user_runnable?, name: :user_runnable
      end
    end
  end
end
