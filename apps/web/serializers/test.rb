module Inferno
  module Web
    module Serializers
      class Test < Serializer
        identifier :id
        field :title
        field :inputs do |test, _options|
          test.inputs.map { |input| { name: input } }
        end
        field :outputs do |test, _options|
          test.outputs.map { |output| { name: output } }
        end
      end
    end
  end
end
