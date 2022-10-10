module Inferno
  module Web
    module Controllers
      class Controller
        # Ensure that each request gets a new instance of the controller.
        def self.call(params)
          new.call(params)
        end

        def self.inherited(subclass)
          super

          # This does some sort of magic that requires it be included in the
          # subclass rather than superclass.
          subclass.include Hanami::Action

          subclass.include Import[repo: "inferno.repositories.#{subclass.resource_name}"]

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
