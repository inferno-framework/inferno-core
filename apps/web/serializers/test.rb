module Inferno
  module Web
    module Serializers
      class Test < Serializer
        identifier :id
        field :title
        field :inputs do |test, _options|
          test.inputs.map { |input| { name: input } }
        end
      end
    end
  end
end
