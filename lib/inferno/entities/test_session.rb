module Inferno
  module Entities
    # A `TestSession` represents an individual testing session.
    #
    # @!attribute id
    #   @return [String] id of the session
    # @!attribute created_at
    #   @return [Time] creation timestamp
    # @!attribute updated_at
    #   @return [Time] update timestamp
    # @!attribute test_suite_id
    #   @return [String] id of the `TestSuite` being run in this session
    # @!attribute test_suite
    #   @return [Inferno::Entities::TestSuite] the `TestSuite` being run in this
    #   session
    # @!attribute test_runs
    #   @return [Array<Inferno::Entities::TestRun>] the `TestRuns` associated
    #   with this session
    # @!attribute results
    #   @return [Array<Inferno::Entities::TestResult>] the `TestResults`
    #   associated with this session
    class TestSession < Entity
      ATTRIBUTES = [:id, :created_at, :updated_at, :test_suite_id, :test_suite, :test_runs, :results].freeze

      include Inferno::Entities::Attributes

      def initialize(params)
        super(params, ATTRIBUTES)
      end
    end
  end
end
