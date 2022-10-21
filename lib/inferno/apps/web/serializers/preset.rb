require_relative 'serializer'

module Inferno
  module Web
    module Serializers
      class Preset < Serializer
        view :summary do
          identifier :id
          field :title
        end
      end
    end
  end
end
