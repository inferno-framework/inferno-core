require_relative 'suite_option'
require_relative 'test_suite'

module Inferno
  module Web
    module Serializers
      class TestSession < Serializer
        identifier :id

        field :test_suite_id
        association :suite_options, blueprint: SuiteOption

        field :test_suite do |session, _options|
          TestSuite.render_as_hash(session.test_suite, view: :full, suite_options: session.suite_options)
        end
      end
    end
  end
end
