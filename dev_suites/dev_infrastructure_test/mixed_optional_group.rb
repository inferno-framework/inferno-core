module InfrastructureTest
  class MixedOptionalGroup < Inferno::TestGroup
    id 'mixed_optional_group'
    title 'Group with an optional and a required test'

    test do
      title 'Optional test'

      optional

      run { pass }
    end

    test do
      title 'Required test'

      run { pass }
    end
  end
end
