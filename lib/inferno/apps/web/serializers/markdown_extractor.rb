require 'blueprinter'
require_relative '../../../utils/markdown_formatter'

module Inferno
  module Web
    module Serializers
      class MarkdownExtractor < Blueprinter::Extractor

        include Inferno::Utils::MarkdownFormatter

        def extract(field_name, object, _local_options, _options = {})
          format_markdown(object.send(field_name))
        end
      end
    end
  end
end
