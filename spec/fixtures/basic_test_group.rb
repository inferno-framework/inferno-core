module BasicTestSuite
  class AbcGroup < Inferno::Entities::TestGroup
    title 'ABC Group'

    input :input1, :input2
    test 'demo_test' do
      1 + 1
    end
  end
end
