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

          subclass.config.default_request_format = :json
          subclass.config.default_response_format = :json

          subclass.define_method(:serialize) do |*args|
            Inferno::Web::Serializers.const_get(self.class.resource_class).render(*args)
          end
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
