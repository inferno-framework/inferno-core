require_relative 'markdown_extractor'
require_relative 'serializer'

module Inferno
  module Web
    module Serializers
      class Input < Serializer
        identifier :name

        field :title, if: :field_present?
        field :description, extractor: MarkdownExtractor, if: :field_present?
        field :type, if: :field_present?
        field :default, if: :field_present?
        field :optional, if: :field_present?
        field :options, if: :field_present?
        field :locked, if: :field_present?
        field :hidden, if: :field_present?
        field :value, if: :field_present?
      end
    end
  end
end
