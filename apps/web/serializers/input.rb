require_relative 'serializer'

module Inferno
  module Web
    module Serializers
      class Input < Serializer
        identifier :name

        field :label, if: :field_present?
        field :description, if: :field_present?
        field :required, if: :field_present?
        field :value, if: :field_present?
      end
    end
  end
end
