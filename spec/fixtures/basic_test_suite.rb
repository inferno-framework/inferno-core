require_relative 'basic_test_group'

module BasicTestSuite
  class Suite < Inferno::Entities::TestSuite
    title 'Basic Test Suite'
    group from: 'BasicTestSuite::AbcGroup'
    id :basic
  end
end
