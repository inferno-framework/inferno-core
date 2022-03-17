module Inferno
  module Web
    module Serializers
      class Test < Serializer
        identifier :id

        field :short_id
        field :title
        field :short_title
        field :available_inputs, name: :inputs, extractor: HashValueExtractor, blueprint: Input
        field :output_definitions, name: :outputs, extractor: HashValueExtractor
        field :description
        field :short_description
        field :input_instructions
        field :user_runnable?, name: :user_runnable
        field :optional?, name: :optional
      end
    end
  end
end
