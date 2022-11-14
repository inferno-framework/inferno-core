module Inferno
  module Entities
    # A `Request` represents a request and response issued during a test.
    #
    # @!attribute id
    #   @return [String] id of the request
    # @!attribute index
    #   @return [String] index of the request. Used for ordering.
    # @!attribute verb
    #   @return [String] http verb
    # @!attribute url
    #   @return [String] request url
    # @!attribute direction
    #   @return [String] incoming/outgoing
    # @!attribute name
    #   @return [String] name for the request
    # @!attribute status
    #   @return [String] http response status code
    # @!attribute request_body
    #   @return [String] body of the http request
    # @!attribute response_body
    #   @return [String] body of the http response
    # @!attribute headers
    #   @return [Array<Inferno::Entities::Header>] http request/response headers
    # @!attribute result_id
    #   @return [String] id of the result for this request
    # @!attribute test_session_id
    #   @return [String] id of the test session for this request
    # @!attribute created_at
    #   @return [Time] creation timestamp
    # @!attribute updated_at
    #   @return [Time] update timestamp
    class Request < Entity
      ATTRIBUTES = [
        :id, :index, :verb, :url, :direction, :name, :status,
        :request_body, :response_body, :result_id, :test_session_id, :created_at,
        :updated_at, :headers
      ].freeze
      SUMMARY_FIELDS = [
        :id, :index, :url, :verb, :direction, :name, :status, :result_id, :created_at, :updated_at
      ].freeze

      include Attributes

      # @private
      def initialize(params)
        super(params, ATTRIBUTES - [:headers, :name])

        @name = params[:name]&.to_sym
        @headers = params[:headers]&.map { |header| header.is_a?(Hash) ? Header.new(header) : header } || []
      end

      # @return [Hash<String, String>]
      def query_parameters
        Addressable::URI.parse(url).query_values || {}
      end

      # Find a response header
      #
      # @param name [String] the header name
      # @return [Inferno::Entities::RequestHeader, nil]
      def response_header(name)
        response_headers.find { |header| header.name.casecmp(name).zero? }
      end

      # Find a request header
      #
      # @param name [String] the header name
      # @return [Inferno::Entities::RequestHeader, nil]
      def request_header(name)
        request_headers.find { |header| header.name.casecmp(name).zero? }
      end

      # All of the request headers
      #
      # @return [Array<Inferno::Entities::RequestHeader>]
      def request_headers
        headers.select(&:request?)
      end

      # All of the response headers
      #
      # @return [Array<Inferno::Entities::RequestHeader>]
      def response_headers
        headers.select(&:response?)
      end

      # Return a hash of the request parameters
      #
      # @return [Hash] A Hash with `:verb`, `:url`, `:headers`, and `:body`
      #   fields
      def request
        {
          verb:,
          url:,
          headers: request_headers,
          body: request_body
        }
      end

      # Return a hash of the response parameters
      #
      # @return [Hash] A Hash with `:status`, `:headers`, and `:body` fields
      def response
        {
          status:,
          headers: response_headers,
          body: response_body
        }
      end

      # @private
      def to_hash
        {
          id:,
          verb:,
          url:,
          direction:,
          status:,
          name:,
          request_body:,
          response_body:,
          result_id:,
          test_session_id:,
          request_headers: request_headers.map(&:to_hash),
          response_headers: response_headers.map(&:to_hash),
          created_at:,
          updated_at:
        }.compact
      end

      # Return the FHIR resource from the response body.
      #
      # @return [FHIR::Model]
      def resource
        FHIR.from_contents(response_body)
      end

      class << self
        # @private
        def from_hanami_request(request, name: nil)
          url = "#{request.base_url}#{request.path}"
          url += "?#{request.query_string}" if request.query_string.present?
          request_headers =
            request.params.env
              .select { |key, _| key.start_with? 'HTTP_' }
              .transform_keys { |key| key.delete_prefix('HTTP_').tr('_', '-').downcase }
              .map { |header_name, value| Header.new(name: header_name, value:, type: 'request') }

          new(
            verb: request.request_method.downcase,
            url:,
            direction: 'incoming',
            name:,
            request_body: request.body.string,
            headers: request_headers
          )
        end

        # @private
        def from_http_response(response, test_session_id:, direction: 'outgoing', name: nil)
          request_headers =
            response.env.request_headers
              .map { |header_name, value| Header.new(name: header_name.downcase, value:, type: 'request') }
          response_headers =
            response.headers
              .map { |header_name, value| Header.new(name: header_name.downcase, value:, type: 'response') }

          new(
            verb: response.env.method,
            url: response.env.url.to_s,
            direction:,
            name:,
            status: response.status,
            request_body: response.env.request_body,
            response_body: response.body,
            test_session_id:,
            headers: request_headers + response_headers
          )
        end

        # @private
        def from_fhir_client_reply(reply, test_session_id:, direction: 'outgoing', name: nil)
          request = reply.request
          response = reply.response
          request_headers = request[:headers]
            .map { |header_name, value| Header.new(name: header_name.downcase, value:, type: 'request') }
          response_headers = response[:headers]
            .map { |header_name, value| Header.new(name: header_name.downcase, value:, type: 'response') }
          request_body =
            if request.dig(:headers, 'Content-Type')&.include?('application/x-www-form-urlencoded')
              URI.encode_www_form(request[:payload])
            else
              request[:payload]
            end

          new(
            verb: request[:method],
            url: request[:url],
            direction:,
            name:,
            status: response[:code].to_i,
            request_body:,
            response_body: response[:body],
            test_session_id:,
            headers: request_headers + response_headers
          )
        end
      end
    end
  end
end
