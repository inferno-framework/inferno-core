module Inferno
  module Web
    module Serializers
      class Test < Serializer
        identifier :id
        field :title
        field :inputs
        field :outputs do |test, _options|
          test.outputs.map { |output| { name: output } }
        end
        field :description
      end
    end
  end
end
