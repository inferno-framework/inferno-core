module BasicTestSuite
  class AbcGroup < Inferno::Entities::TestGroup
    title 'ABC Group'

    test 'demo_test' do
      1 + 1
    end
  end
end
