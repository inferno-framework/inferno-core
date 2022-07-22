module Inferno
  module Web
    module Serializers
      class Test < Serializer
        identifier :id

        field :short_id
        field :title
        field :short_title
        field :inputs do |test, options|
          suite_options = options[:suite_options]
          Input.render_as_hash(test.available_inputs(suite_options).values)
        end
        field :output_definitions, name: :outputs, extractor: HashValueExtractor
        field :description
        field :short_description
        field :input_instructions
        field :user_runnable?, name: :user_runnable
        field :optional?, name: :optional
      end
    end
  end
end
