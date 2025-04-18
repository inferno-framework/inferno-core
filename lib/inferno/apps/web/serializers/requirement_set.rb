require_relative 'serializer'

module Inferno
  module Web
    module Serializers
      class RequirementSet < Serializer
        identifier :identifier

        field :title
      end
    end
  end
end
