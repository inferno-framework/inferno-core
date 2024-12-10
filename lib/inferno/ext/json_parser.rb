module Hanami
  module Middleware
    class BodyParser
      class JsonParser
        def self.mime_types
          ['application/json', 'application/vnd.api+json', 'application/fhir+json']
        end
      end
    end
  end
end
