require_relative 'test_suite'

module Inferno
  module Web
    module Serializers
      class TestSession < Serializer
        identifier :id

        field :test_suite_id

        association :test_suite, blueprint: TestSuite, view: :full
        # association :test_run, blueprint: TestRun
        # association :results, blueprint: Result
      end
    end
  end
end
