module Inferno
  module Entities
    # A `Message` represents a message generated during a test.
    #
    # @attr_reader [String] id of the message
    # @attr_reader [String] index of the message. Used for ordering.
    # @attr_reader [String] result_id
    # @attr_reader [Inferno::Entities::Result] result
    # @attr_reader [String] type
    # @attr_reader [String] message
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
