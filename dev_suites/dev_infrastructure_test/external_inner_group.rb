require_relative 'external_test1'

module InfrastructureTest
  class ExternalInnerGroup < Inferno::TestGroup
    id 'external_inner_group'
    title 'External Inner Group'

    input :external_inner_group_input, type: 'text'
    output :external_inner_group_output

    fhir_client :external_inner_group do
      url 'EXTERNAL_INNER_GROUP'
    end

    test from: 'external_test1'
  end
end
