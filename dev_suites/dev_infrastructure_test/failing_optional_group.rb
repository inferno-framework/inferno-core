module InfrastructureTest
  class FailingOptionalGroup < Inferno::TestGroup
    id 'failing_optional_group'
    title 'Failing Optional Group'

    optional

    test 'Test in Optional Group' do
      optional

      run { assert false }
    end
  end
end
