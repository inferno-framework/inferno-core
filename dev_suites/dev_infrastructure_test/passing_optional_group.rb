module InfrastructureTest
  class PassingOptionalGroup < Inferno::TestGroup
    id 'passing_optional_group'
    title 'Passing Optional Group'

    optional

    test 'Test in Optional Group' do
      optional

      run { assert true }
    end
  end
end
