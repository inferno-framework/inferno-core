module Inferno
  module Web
    module Serializers
      class Message < Serializer
        field :type
        field :message
      end
    end
  end
end
