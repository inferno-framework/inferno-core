module InfrastructureTest
  class PassingOptionalGroup < Inferno::TestGroup
    id 'passing_optional_group'
    title 'Passing Optional Group'

    optional

    test 'Passing test in Optional Group' do
      optional

      run { assert true }
    end

    test 'Failing test in Optional Group' do
      optional

      run { assert false }
    end
  end
end
