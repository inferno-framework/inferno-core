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
    class Header < Entity
      ATTRIBUTES = [:id, :request_id, :name, :type, :value].freeze

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
          id:,
          request_id:,
          type:,
          name:,
          value:
        }.compact
      end
    end
  end
end
