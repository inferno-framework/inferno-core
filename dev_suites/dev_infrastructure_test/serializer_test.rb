module InfrastructureTest
  class SerializerTest < Inferno::Test
    id :infrastructure_serializer_test
    title 'TEST_TITLE'
    description 'TEST_DESCRIPTION'

    input :input1,
          title: 'INPUT1_TITLE',
          description: 'INPUT1_DESCRIPTION',
          default: 'INPUT1_DEFAULT',
          type: 'text'
    input :input2,
          title: 'INPUT2_TITLE',
          description: 'INPUT2_DESCRIPTION',
          default: 'INPUT2_DEFAULT',
          type: 'text'

    output :output1, :output2

    verifies_requirements 'sample-criteria@1', 'sample-criteria@2'

    run { pass }
  end
end
