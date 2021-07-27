module Inferno
  module Entities
    # A `TestRun` represents a request to execute an executable set of tests.
    #
    # @attr_accessor [String] id of the test input
    # @attr_accessor [String] test_session_id
    # @attr_accessor [String] status
    # @attr_accessor [String] test_suite_id
    # @attr_accessor [String] test_group_id
    # @attr_accessor [String] test_id
    class TestRun < Entity
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
