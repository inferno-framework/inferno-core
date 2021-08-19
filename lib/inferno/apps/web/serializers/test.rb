require_relative 'hash_values_extractor'

module Inferno
  module Web
    module Serializers
      class Test < Serializer
        identifier :id
        field :title
        field :inputs, extractor: HashValuesExtractor, blueprint: Input
        field :outputs, extractor: HashValuesExtractor
        field :description
      end
    end
  end
end
