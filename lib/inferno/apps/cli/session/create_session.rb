require 'faraday'
require_relative 'connection'
require_relative 'errors'

module Inferno
  module CLI
    module Session
      class CreateSession
        include Connection
        include Errors
        attr_accessor :suite_id, :options

        def initialize(suite_id, options)
          self.suite_id = suite_id
          self.options = options
        end

        def run
          request_body = { test_suite_id: suite_id }
          request_body[:preset_id] = options[:preset_id] if options[:preset_id].present?
          request_body[:suite_options] = suite_options_list if options[:suite_options].present?

          response = connection.post('api/test_sessions', request_body.to_json, content_type: 'application/json')

          handle_web_api_error(response, :session_create) if response.status != 200

          puts JSON.pretty_generate(JSON.parse(response.body))
          exit(0)
        end

        def suite_options_list
          options[:suite_options].keys.map do |option|
            { id: option, value: options[:suite_options][option] }
          end
        end
      end
    end
  end
end
