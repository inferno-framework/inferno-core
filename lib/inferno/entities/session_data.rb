module Inferno
  module Entities
    # `SessionData` represents a piece of saved state for a `TestSession`.
    # These are used to store test inputs and outputs.
    #
    # @attr_accessor [String] id of the test input
    # @attr_accessor [String] name
    # @attr_accessor [String] value
    # @attr_accessor [String] test_session_id
    # @attr_accessor [Time] created_at
    # @attr_accessor [Time] updated_at
    class SessionData < Entity
      ATTRIBUTES = [:id, :name, :value, :test_session_id, :created_at, :updated_at].freeze

      include Inferno::Entities::Attributes

      def initialize(params)
        super(params, ATTRIBUTES)
      end

      def to_hash
        {
          id: id,
          name: name,
          value: value,
          test_session_id: test_session_id,
          created_at: created_at,
          updated_at: updated_at
        }
      end
    end
  end
end
