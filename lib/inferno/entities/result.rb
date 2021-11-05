module Inferno
  module Entities
    # A `Result` represents the result of running a `Test`, `TestGroup`,
    # or `TestSuite`
    #
    # @!attribute id
    #   @return [String] id of the session
    # @!attribute created_at
    #   @return [Time] creation timestamp
    # @!attribute updated_at
    #   @return [Time] update timestamp
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
    # @!attribute result
    #   @return [String] the result (`pass`, `fail`, `skip`, `omit`, `error`,
    #   `running`, `wait`, `cancel`)
    # @!attribute result_message
    #   @return [String] summary message for this result
    # @!attribute test_run_id
    #   @return [String] the `TestRun` this result belongs to
    # @!attribute test_session_id
    #   @return [String] the `TestSession` this result belongs to
    # @!attribute messages
    #   @return [Array<Inferno::Entities::Message>] additional messages for this
    #   result
    # @!attribute requests
    #   @return [Array<Inferno::Entities::Request>] summaries of the requests
    #   associated with this result
    # @!attribute input_json
    #   @return [String] JSON string of the inputs used for this result
    # @!attribute output_json
    #   @return [String] JSON string of the outputs created by this result
    class Result < Entity
      ATTRIBUTES = [
        :id, :created_at, :updated_at, :test_id, :test, :test_group_id,
        :test_group, :test_suite_id, :test_suite, :test_run_id,
        :test_session_id, :result, :result_message, :messages, :requests,
        :input_json, :output_json
      ].freeze
      RESULT_OPTIONS = ['cancel', 'wait', 'running', 'error', 'fail', 'skip', 'pass', 'omit'].freeze

      include Inferno::Entities::Attributes
      include Inferno::Entities::HasRunnable

      def initialize(params)
        super(params, ATTRIBUTES - [:messages, :requests])

        @messages = (params[:messages] || []).map { |message| Message.new(message) }
        @requests = (params[:requests] || []).map { |request| Request.new(request) }
      end

      def optional?
        runnable.optional?
      end

      def required?
        runnable.required?
      end

      # @return [Boolean]
      def waiting?
        result == 'wait'
      end
    end
  end
end
