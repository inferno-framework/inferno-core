module Inferno
  module Web
    module Serializers
      class TestSuite < Serializer
        view :summary do
          identifier :id
          field :title
          field :description
        end

        view :full do
          include_view :summary
          association :groups, name: :test_groups, blueprint: TestGroup
        end
      end
    end
  end
end
