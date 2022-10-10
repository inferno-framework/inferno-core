module Inferno
  module Entities
    # `SessionData` represents a piece of saved state for a `TestSession`.
    # These are used to store test inputs and outputs.
    #
    # @!attribute id
    #   @return [String] id of the test input
    # @!attribute name
    #   @return [String]
    # @!attribute value
    #   @return [String]
    # @!attribute test_session_id
    #   @return [String]
    # @!attribute created_at
    #   @return [Time]
    # @!attribute updated_at
    #   @return [Time]
    class SessionData < Entity
      ATTRIBUTES = [:id, :name, :value, :test_session_id, :created_at, :updated_at].freeze

      include Inferno::Entities::Attributes

      def initialize(params)
        super(params, ATTRIBUTES)
      end

      def to_hash
        {
          id:,
          name:,
          value:,
          test_session_id:,
          created_at:,
          updated_at:
        }
      end
    end
  end
end
