module Inferno
  module Web
    module Serializers
      class Preset < Serializer
        view :summary do
          identifier :id
          field :title
        end

        # view :full do
        #   include_view :summary
        #   field :inputs, blueprint: Input
        # end
      end
    end
  end
end
