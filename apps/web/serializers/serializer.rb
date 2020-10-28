module Inferno
  module Web
    module Serializers
      class Serializer < Blueprinter::Base
        def self.field_present?(field_name, result, options)
          name = options[:name] || field_name
          if result.respond_to?(:[])
            result[name].present?
          else
            result.send(name).present?
          end
        end
      end
    end
  end
end
