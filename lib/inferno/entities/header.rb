module Inferno
  module Entities
    # A `Header` represents an HTTP request/response header
    #
    # @!attribute id
    #   @return [String] id of the header
    # @!attribute request_id
    #   @return [String] index of the HTTP request
    # @!attribute name
    #   @return [String] header name
    # @!attribute value
    #   @return [String] header value
    # @!attribute type
    #   @return [String] request/response
    # @!attribute created_at
    #   @return [Time]
    # @!attribute updated_at
    #   @return [Time]
    class Header < Entity
      ATTRIBUTES = [:id, :request_id, :name, :type, :value, :created_at, :updated_at].freeze

      include Inferno::Entities::Attributes

      def initialize(params)
        super(params, ATTRIBUTES)
      end

      def request?
        type == 'request'
      end

      def response?
        type == 'response'
      end

      def to_hash
        {
          id: id,
          request_id: request_id,
          type: type,
          name: name,
          value: value,
          created_at: created_at,
          updated_at: updated_at
        }.compact
      end
    end
  end
end
