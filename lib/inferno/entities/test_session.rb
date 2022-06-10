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
    # @!attribute suite_options
    #   @return [Hash] the suite options associated with this session
    class TestSession < Entity
      ATTRIBUTES = [
        :id,
        :created_at,
        :updated_at,
        :test_suite_id,
        :test_suite,
        :test_runs,
        :results,
        :suite_options
      ].freeze

      include Inferno::Entities::Attributes

      def initialize(params)
        super(params, ATTRIBUTES)

        if suite_options.is_a? String # rubocop:disable Style/GuardClause
          self.suite_options = JSON.parse(suite_options)&.deep_symbolize_keys
        end
      end

      def to_hash
        session_hash = (self.class::ATTRIBUTES - [:suite_options]).each_with_object({}) do |attribute, hash|
          hash[attribute] = send(attribute)
        end

        session_hash[:suite_options] = JSON.generate(suite_options)

        session_hash.compact
      end
    end
  end
end
