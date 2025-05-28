require 'oj'
require 'blueprinter'
require_relative '../../../feature'

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

        # When removing the feature flag, replace all instances of this method
        # with `.field_present?`
        def self.field_present_and_requirements_enabled?(field_name, result, options)
          field_present?(field_name, result, options) && Feature.requirements_enabled?
        end
      end
    end
  end
end
