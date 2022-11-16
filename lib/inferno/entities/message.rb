module Inferno
  module Entities
    # A `Message` represents a message generated during a test.
    #
    # @!attribute id
    #   @return [String] id of the message
    # @!attribute index
    #   @return [String] index of the message. Used for ordering.
    # @!attribute result_id
    #   @return [String]
    # @!attribute result
    #   @return [Inferno::Entities::Result]
    # @!attribute type
    #   @return [String]
    # @!attribute message
    #   @return [String]
    class Message < Entity
      ATTRIBUTES = [:id, :index, :message, :result_id, :result, :type].freeze
      TYPES = ['error', 'warning', 'info'].freeze

      include Inferno::Entities::Attributes

      def initialize(params)
        super(params, ATTRIBUTES)
      end
    end
  end
end
