require_relative 'serializer'

module Inferno
  module Web
    module Serializers
      class Requirement < Serializer
        identifier :id

        field :requirement
        field :conformance
        field :actors
        field :sub_requirements
        field :conditionality
        field :url, if: :field_present?
        field :not_tested_reason, if: :field_present?
        field :not_tested_details, if: :field_present?
      end
    end
  end
end
