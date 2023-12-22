module InfrastructureTest
  class EmptyGroup < Inferno::TestGroup
    id 'empty_group'
    title 'Empty Group'

    fhir_client :empty_group do
      url 'EMPTY_GROUP'
    end

  end
end
