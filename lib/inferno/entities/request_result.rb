module Inferno
  module Entities
    # A `RequestResult` represents an association a between a request and a result.
    # If a result uses or creates a request, that relationship is saved here.
    #
    # @attr_reader [String] id id of the request-result
    # @attr_reader [String] result_id id of the result
    # @attr_reader [String] request_id id of the request
    class RequestResult < Entity
      ATTRIBUTES = [:id, :result_id, :request_id].freeze
      include Inferno::Entities::Attributes

      def initialize(params)
        super(params, ATTRIBUTES)
      end

      def to_hash
        {
          id: id,
          request_id: request_id,
          result_id: result_id
        }.compact
      end
    end
  end
end
