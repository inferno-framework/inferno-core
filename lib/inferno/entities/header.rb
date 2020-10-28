module Inferno
  module Entities
    # A `Header` represents an HTTP request/response header
    #
    # @attr_reader [String] id of the header
    # @attr_reader [String] request_id index of the HTTP request
    # @attr_reader [String] name header name
    # @attr_reader [String] value header value
    # @attr_reader [String] type request/response
    # @attr_reader [Time] created_at
    # @attr_reader [Time] updated_at
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
