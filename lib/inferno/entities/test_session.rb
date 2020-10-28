module Inferno
  module Entities
    # A `TestSession` represents an individual testing session.
    #
    # @attr_reader [String] id id of the session
    # @attr_reader [Time] created_at creation timestamp
    # @attr_reader [Time] updated_at update timestamp
    # @attr_reader [String] test_suite_id id of the `TestSuite` being run in
    #   this session
    # @attr_reader [Inferno::Entities::TestSuite] test_suite the `TestSuite` being run in
    #   this session
    # @attr_reader [Array<Inferno::Entities::TestRun>] test_runs the `TestRuns`
    #   associated with this session
    # @attr_reader [Array<Inferno::Entities::TestResult>] test_results the
    #   `TestResults` associated with this session
    class TestSession < Entity
      ATTRIBUTES = [:id, :created_at, :updated_at, :test_suite_id, :test_suite, :test_runs, :test_results].freeze

      include Inferno::Entities::Attributes

      def initialize(params)
        super(params, ATTRIBUTES)
      end
    end
  end
end
