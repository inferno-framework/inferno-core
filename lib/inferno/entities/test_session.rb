module Inferno
  module Entities
    # A `TestSession` represents an individual testing session.
    #
    # @attr_accessor [String] id id of the session
    # @attr_accessor [Time] created_at creation timestamp
    # @attr_accessor [Time] updated_at update timestamp
    # @attr_accessor [String] test_suite_id id of the `TestSuite` being run in
    #   this session
    # @attr_accessor [Inferno::Entities::TestSuite] test_suite the `TestSuite` being run in
    #   this session
    # @attr_accessor [Array<Inferno::Entities::TestRun>] test_runs the `TestRuns`
    #   associated with this session
    # @attr_accessor [Array<Inferno::Entities::TestResult>] results the
    #   `TestResults` associated with this session
    class TestSession < Entity
      ATTRIBUTES = [:id, :created_at, :updated_at, :test_suite_id, :test_suite, :test_runs, :results].freeze

      include Inferno::Entities::Attributes

      def initialize(params)
        super(params, ATTRIBUTES)
      end
    end
  end
end
