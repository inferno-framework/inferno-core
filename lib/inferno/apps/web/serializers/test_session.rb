require_relative 'test_suite'

module Inferno
  module Web
    module Serializers
      class TestSession < Serializer
        identifier :id

        field :test_suite_id
        field :suite_options do |session, _options|
          (session.suite_options.presence || {}).each_with_object([]) do |(key, value), formatted_options|
            formatted_options << {
              id: key,
              value: value
            }
          end
        end

        field :test_suite do |session, _options|
          TestSuite.render_as_hash(session.test_suite, view: :full, suite_options: session.suite_options)
        end
      end
    end
  end
end
