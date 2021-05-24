require_relative 'serializer'

module Inferno
  module Web
    module Serializers
      class Header < Serializer
        field :name
        field :value
      end
    end
  end
end
