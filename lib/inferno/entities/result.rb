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
        runnable.nil? || runnable.optional?
      end

      def required?
        !optional?
      end

      # @return [Boolean]
      def waiting?
        result == 'wait'
      end

      def inputs
        input_json.present? ? JSON.parse(input_json) : []
      end

      def outputs
        output_json.present? ? JSON.parse(output_json) : []
      end

      # Flags large inputs or outputs and replaces their values with a reference message.
      #
      # This method inspects either the `inputs` or `outputs` array and,
      # for each item whose `value` exceeds the configured size threshold, sets `is_large: true`
      # and replaces the `value` with a message pointing to the full content endpoint.
      #
      # @param io_type [String] Must be either `'inputs'` or `'outputs'`.
      # @return [Array<Hash>] The mutated list of inputs or outputs.
      def handle_large_io(io_type)
        io_array = public_send(io_type)

        io_array.each do |io|
          next unless io_is_large?(io['value'])

          io['is_large'] = true
          io['value'] = <<~MESSAGE
            #{io_type.singularize.capitalize} is too large to display, please visit
            #{Inferno::Application['base_url']}/api/test_sessions/#{test_session_id}/results/#{id}/io/#{io_type}/#{io['name']}
            for details
          MESSAGE
        end

        io_array
      end

      # @private
      def io_is_large?(io_value)
        size_in_char = io_value.is_a?(String) ? io_value.length : io_value.to_json.length
        size_in_char > ENV.fetch('MAX_IO_DISPLAY_CHAR', 10000).to_i
      end
    end
  end
end
