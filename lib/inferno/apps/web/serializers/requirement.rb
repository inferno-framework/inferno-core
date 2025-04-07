require_relative 'serializer'

module Inferno
  module Web
    module Serializers
      class Requirement < Serializer
        identifier :id

        field :requirement
        field :conformance
        field :actor
        field :sub_requirements
        field :conditionality
        field :url, if: :field_present?
      end
    end
  end
end
