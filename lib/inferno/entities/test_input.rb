module Inferno
  module Entities
    # A `TestRun` represents an input definition in a test.
    #
    # @attr_reader [String] id of the test input
    # @attr_reader [String] status
    # @attr_reader [String] test_suite_id
    class TestInput
      attr_reader :id, :status, :test_suite_id

      # How to define test run inputs?  Class in this file?  Separate Entity?

      def initialize(params)
        @id = params[:id]
        @status = params[:name]
        @test_suite_id = params[:test_suite_id]
      end
    end
  end
end
