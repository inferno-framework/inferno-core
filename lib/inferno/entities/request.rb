require 'pry'
module Inferno
  module Entities
    # A `Request` represents a request and response issued during a test.
    #
    # @attr_reader [String] id of the request
    # @attr_reader [String] index of the request. Used for ordering.
    # @attr_reader [String] verb http verb
    # @attr_reader [String] url request url
    # @attr_reader [String] direction incoming/outgoing
    # @attr_reader [String] name name for the request
    # @attr_reader [String] status http response status code
    # @attr_reader [String] request_body body of the http request
    # @attr_reader [String] response_body body of the http response
    # @attr_reader [Array<Inferno::Entities::Header>] headers http
    #   request/response headers
    # @attr_reader [String] result_id id of the result for this request
    # @attr_reader [String] test_session_id id of the test session for this request
    # @attr_reader [Time] created_at creation timestamp
    # @attr_reader [Time] updated_at update timestamp
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
        response_headers.find { |header| header.name == name.downcase }
      end

      # Find a request header
      #
      # @param name [String] the header name
      # @return [Inferno::Entities::RequestHeader, nil]
      def request_header(name)
        request_headers.find { |header| header.name == name.downcase }
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
      # @return [Hash]
      def request
        {
          verb: verb,
          url: url,
          headers: request_headers,
          body: request_body
        }
      end

      # Return a hash of the response parameters
      #
      # @return [Hash]
      def response
        {
          status: status,
          headers: response_headers,
          body: response_body
        }
      end

      # @api private
      def to_hash
        {
          id: id,
          verb: verb,
          url: url,
          direction: direction,
          status: status,
          name: name,
          request_body: request_body,
          response_body: response_body,
          result_id: result_id,
          test_session_id: test_session_id,
          request_headers: request_headers.map(&:to_hash),
          response_headers: response_headers.map(&:to_hash),
          created_at: created_at,
          updated_at: updated_at
        }.compact
      end

      # Return the FHIR resource from the response body.
      #
      # @return [FHIR::Model]
      def resource
        FHIR.from_contents(response_body)
      end

      class << self
        # @api private
        def from_rack_env(env, name: nil)
          rack_request = env['router.request'].rack_request
          url = "#{rack_request.base_url}#{rack_request.path}"
          url += "?#{rack_request.query_string}" if rack_request.query_string.present?
          request_headers =
            env
              .select { |key, _| key.start_with? 'HTTP_' }
              .transform_keys { |key| key.delete_prefix('HTTP_').tr('_', '-').downcase }
              .map { |header_name, value| Header.new(name: header_name, value: value, type: 'request') }

          new(
            verb: rack_request.request_method.downcase,
            url: url,
            direction: 'incoming',
            name: name,
            request_body: rack_request.body.string,
            headers: request_headers
          )
        end

        # @api private
        def from_http_response(response, test_session_id:, direction: 'outgoing', name: nil)
          request_headers =
            response.env.request_headers
              .map { |header_name, value| Header.new(name: header_name.downcase, value: value, type: 'request') }
          response_headers =
            response.headers
              .map { |header_name, value| Header.new(name: header_name.downcase, value: value, type: 'response') }

          new(
            verb: response.env.method,
            url: response.env.url.to_s,
            direction: direction,
            name: name,
            status: response.status,
            request_body: response.env.request_body,
            response_body: response.body,
            test_session_id: test_session_id,
            headers: request_headers + response_headers
          )
        end

        # @api private
        def from_fhir_client_reply(reply, test_session_id:, direction: 'outgoing', name: nil)
          request = reply.request
          response = reply.response
          request_headers = request[:headers]
            .map { |header_name, value| Header.new(name: header_name.downcase, value: value, type: 'request') }
          response_headers = response[:headers]
            .map { |header_name, value| Header.new(name: header_name.downcase, value: value, type: 'response') }

          new(
            verb: request[:method],
            url: request[:url],
            direction: direction,
            name: name,
            status: response[:code].to_i,
            request_body: request[:payload],
            response_body: response[:body],
            test_session_id: test_session_id,
            headers: request_headers + response_headers
          )
        end
      end
    end
  end
end
