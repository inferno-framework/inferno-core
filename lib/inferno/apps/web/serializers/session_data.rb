require_relative 'serializer'

module Inferno
  module Web
    module Serializers
      class SessionData < Serializer
        field :name
        field :value
      end
    end
  end
end
