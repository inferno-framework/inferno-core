require_relative 'input'
require_relative 'result'

module Inferno
  module Web
    module Serializers
      class TestRun < Serializer
        identifier :id
        field :test_session_id

        field :status
        field :test_count do |test_run, options|
          test_run.test_count(options[:suite_options])
        end

        field :test_group_id, if: :field_present?
        field :test_suite_id, if: :field_present?
        field :test_id, if: :field_present?

        association :results, blueprint: Result
        association :inputs, blueprint: Input
      end
    end
  end
end
