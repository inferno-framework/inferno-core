module Inferno
  module Entities
    # A `Header` represents an HTTP request/response header
    #
    # @attr_accessor [String] id of the header
    # @attr_accessor [String] request_id index of the HTTP request
    # @attr_accessor [String] name header name
    # @attr_accessor [String] value header value
    # @attr_accessor [String] type request/response
    # @attr_accessor [Time] created_at
    # @attr_accessor [Time] updated_at
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
