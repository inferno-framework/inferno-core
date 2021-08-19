module Inferno
  module Web
    module Serializers
      class HashValuesExtractor < Blueprinter::Extractor
        def extract(field_name, object, _local_options, _options)
          object.send(field_name).values
        end
      end
    end
  end
end
