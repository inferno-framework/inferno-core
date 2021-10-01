module Inferno
  module Entities
    # A `TestRun` represents a request to execute an executable set of tests.
    #
    # @!attribute id
    #   @return [String] id of the test run
    # @!attribute created_at
    #   @return [Time] creation timestamp
    # @!attribute updated_at
    #   @return [Time] update timestamp
    # @!attribute test_session_id
    #   @return [String]
    # @!attribute status
    #   @return [String]
    # @!attribute test_id
    #   @return [String, nil] id of the `Test` this result belongs to
    # @!attribute test
    #   @return [Test, nil] the `Test` this result belongs to
    # @!attribute test_group_id
    #   @return [String, nil] id of the `TestGroup` this result belongs to
    # @!attribute test_group
    #   @return [TestGroup, nil] the `TestGroup` this result belongs to
    # @!attribute test_suite_id
    #   @return [String, nil] id of the `TestSuite` this result belongs to
    # @!attribute test_suite
    #   @return [TestSuite, nil] the `TestSuite` this result belongs to
    # @!attribute inputs
    #   @return [Array<Hash>]
    # @!attribute results
    #   @return [Array<Inferno::Entities::Result>]
    # @!attribute identifier
    #   @return [String, nil] identfier for a waiting `TestRun`
    # @!attribute wait_timeout
    class TestRun < Entity
      STATUS_OPTIONS = ['queued', 'running', 'waiting', 'done'].freeze
      ATTRIBUTES = [
        :id,
        :test_session_id,
        :status,
        :test_suite_id,
        :test_group_id,
        :test_id,
        :test,
        :test_group,
        :test_suite,
        :inputs,
        :results,
        :identifier,
        :wait_timeout,
        :created_at,
        :updated_at
      ].freeze

      include Inferno::Entities::Attributes

      attr_accessor :test_session

      # How to define test run inputs?  Class in this file?  Separate Entity?

      def initialize(params)
        super(params, ATTRIBUTES)

        @test_session = params[:test_session]
      end

      def runnable
        return @runnable if @runnable

        @runnable = (test || test_group || test_suite || load_runnable)
      end

      def to_hash
        super.merge(test_session: test_session).compact
      end

      def test_count
        @test_count ||= runnable.test_count
      end

      private

      def load_runnable
        if test_id.present?
          @test = Inferno::Repositories::Tests.new.find(test_id)
        elsif test_group_id.present?
          @test_group = Inferno::Repositories::TestGroups.new.find(test_group_id)
        elsif test_suite_id.present?
          @test_suite = Inferno::Repositories::TestSuites.new.find(test_suite_id)
        end
      end
    end
  end
end
