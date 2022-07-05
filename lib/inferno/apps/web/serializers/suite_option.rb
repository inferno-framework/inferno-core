module Inferno
  module Web
    module Serializers
      class SuiteOption < Serializer
        identifier :id
        field :title, if: :field_present?
        field :description, if: :field_present?
        field :list_options, if: :field_present?
        field :value, if: :field_present?
      end
    end
  end
end
