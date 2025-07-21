require_relative 'suite_option'
require_relative 'test_suite'

module Inferno
  module Web
    module Serializers
      class TestSession < Serializer
        identifier :id

        field :test_suite_id
        association :suite_options, blueprint: SuiteOption

        field :test_suite do |test_session, _options|
          suite_requirement_ids =
            Inferno::Repositories::Requirements.new
              .requirements_for_suite(test_session.test_suite_id, test_session.id)
              .map(&:id)

          TestSuite.render_as_hash(
            test_session.test_suite,
            view: :full,
            suite_options: test_session.suite_options,
            suite_requirement_ids:
          )
        end
      end
    end
  end
end
