module Inferno
  module Entities
    # A `Result` represents the result of running a `Test`, `TestGroup`,
    # or `TestSuite`
    #
    # @attr_accessor [String] id id of the session
    # @attr_accessor [Time] created_at creation timestamp
    # @attr_accessor [Time] updated_at update timestamp
    # @attr_accessor [String] reference_type type of entity this result belongs
    #   to (`Test`, `TestGroup`, or `TestSuite`)
    # @attr_accessor [String, nil] test_id id of the `Test` this result belongs
    #   to
    # @attr_accessor [Test, nil] test the `Test` this result belongs to
    # @attr_accessor [String, nil] test_group_id id of the `TestGroup` this
    #   result belongs to
    # @attr_accessor [TestGroup, nil] test_group the `TestGroup` this result
    #   belongs to
    # @attr_accessor [String, nil] test_suite_id id of the `TestSuite` this
    #   result belongs to
    # @attr_accessor [TestSuite, nil] test_suite the `TestSuite` this result
    #   belongs to
    # @attr_accessor [String] result the result (`pass`, `fail`, `skip`, `omit`,
    #   `error`, `running`, `wait`, `cancel`)
    # @attr_accessor [String] result_message summary message for this result
    # @attr_accessor [String] test_run_id the `TestRun` this result belongs to
    # @attr_accessor [String] test_session_id the `TestSession` this result
    #   belongs to
    # @attr_accessor [Array<Inferno::Entities::Message>] messages additional
    #   messages for this result
    # @attr_accessor [Array<Inferno::Entities::Request>] request_summaries
    #   summaries of the requests associated with this result
    # @attr_accessor [String] input_json JSON string of the inputs used for this
    #   result
    # @attr_accessor [String] output_json JSON string of the outputs created by
    #   this result
    class Result < Entity
      ATTRIBUTES = [
        :id, :created_at, :updated_at, :test_id, :test, :test_group_id,
        :test_group, :test_suite_id, :test_suite, :test_run_id,
        :test_session_id, :result, :result_message, :messages, :requests,
        :input_json, :output_json
      ].freeze
      RESULT_OPTIONS = ['cancel', 'wait', 'running', 'error', 'fail', 'skip', 'omit', 'pass'].freeze

      include Inferno::Entities::Attributes

      def initialize(params)
        super(params, ATTRIBUTES - [:messages, :requests, :inputs, :outputs])

        @input_json = JSON.generate(params[:inputs])
        @output_json = JSON.generate(params[:outputs])
        @messages = (params[:messages] || []).map { |message| Message.new(message) }
        @requests = (params[:requests] || []).map { |request| Request.new(request) }
      end

      # @return [Inferno::Entities::Test, Inferno::Entities::TestGroup, Inferno::Entities::TestSuite]
      def runnable
        test || test_group || test_suite
      end

      # @return [Boolean]
      def waiting?
        result == 'wait'
      end
    end
  end
end
