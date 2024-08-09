module BasicTestSuite
  class DefGroup < Inferno::Entities::TestGroup
    title 'DEF Group'

    run_as_group

    test 'this_test_cannot_run_alone' do
      run { 2 + 2 }
    end
  end
end
