require_relative 'serializer_test'

module DevelopmentTestKit
  class SerializerGroup < Inferno::TestGroup
    id :infrastructure_serializer_group
    title 'GROUP_TITLE'
    description 'GROUP_DESCRIPTION'

    input :input3,
          description: 'INPUT3_DESCRIPTION',
          default: 'INPUT3_DEFAULT',
          type: 'text'
    input :markdown_input,
          description: %(
            # Markdown Title

            Markdown description
          ),
          default: 'INPUT3_DEFAULT',
          type: 'text'

    output :output3

    test from: :infrastructure_serializer_test
  end
end
