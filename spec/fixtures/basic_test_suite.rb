module BasicTestSuite
  class Suite < Inferno::Entities::TestSuite
    title 'Basic Test Suite'
    group from: 'BasicTestSuite::AbcGroup'
  end
end
