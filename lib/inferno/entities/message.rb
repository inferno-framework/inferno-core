module Inferno
  module Entities
    # A `Message` represents a message generated during a test.
    #
    # @attr_accessor [String] id of the message
    # @attr_accessor [String] index of the message. Used for ordering.
    # @attr_accessor [String] result_id
    # @attr_accessor [Inferno::Entities::Result] result
    # @attr_accessor [String] type
    # @attr_accessor [String] message
    # @attr_accessor [Time] created_at
    # @attr_accessor [Time] updated_at
    class Message < Entity
      ATTRIBUTES = [:id, :index, :message, :result_id, :result, :type, :created_at, :updated_at].freeze
      TYPES = ['error', 'warning', 'info'].freeze

      include Inferno::Entities::Attributes

      def initialize(params)
        super(params, ATTRIBUTES)
      end
    end
  end
end
