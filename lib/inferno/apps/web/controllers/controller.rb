require 'hanami/action/mime/request_mime_weight'

module Inferno
  module Web
    module Controllers
      class Controller < Hanami::Action
        def self.call(...)
          new.call(...)
        end

        def self.inherited(subclass)
          super

          subclass.include Import[repo: "inferno.repositories.#{subclass.resource_name}"]

          subclass.define_method(:serialize) do |*args|
            Inferno::Web::Serializers.const_get(self.class.resource_class).render(*args)
          end

          # Hanami Controller 2.0.0 removes the ability to set a default
          # Content-Type response header, so set it manually if it hasn't been
          # set.
          subclass.after { |_req, res| res.format = :json if res.format == :all && res.body&.first&.first == '{' }
        end

        def self.resource_name
          name.split('::')[-2].underscore
        end

        def self.resource_class
          name.split('::')[-2].singularize
        end
      end
    end
  end
end
