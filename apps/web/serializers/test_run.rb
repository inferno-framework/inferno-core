module Inferno
  module Web
    module Serializers
      class TestRun < Serializer
        identifier :id
        field :test_session_id

        field :status

        field :test_group_id, if: :field_present?
        field :test_suite_id, if: :field_present?
        field :test_id, if: :field_present?

        association :results, blueprint: Result
        association :inputs, blueprint: Input
      end
    end
  end
end
