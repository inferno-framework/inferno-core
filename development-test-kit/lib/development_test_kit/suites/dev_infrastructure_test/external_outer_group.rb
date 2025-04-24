require_relative 'external_inner_group'

module DevelopmentTestKit
  class ExternalOuterGroup < Inferno::TestGroup
    id 'external_outer_group'
    title 'External Outer Group'

    input :external_outer_group_input
    output :external_outer_group_output

    fhir_client :external_outer_group do
      url 'EXTERNAL_OUTER_GROUP'
    end

    group from: 'external_inner_group'
  end
end
