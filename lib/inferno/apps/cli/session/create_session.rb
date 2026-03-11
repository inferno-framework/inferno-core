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
          puts JSON.pretty_generate(create_session)
          exit(0)
        end

        def create_session
          request_body = { test_suite_id: suite_id }
          request_body[:preset_id] = options[:preset_id] if options[:preset_id].present?
          request_body[:suite_options] = suite_options_list if options[:suite_options].present?

          response = post('api/test_sessions', request_body.to_json, content_type: 'application/json')

          handle_web_api_error(response, :session_create) if response.status != 200

          JSON.parse(response.body)
        end

        def suite_option_definitions
          @suite_option_definitions ||= begin
            response = get("api/test_suites/#{suite_id}")
            if response.status != 200
              puts JSON.pretty_generate({ errors: "Suite '#{suite_id}' not found at '#{base_url}'" })
              exit(3)
            end
            JSON.parse(response.body)['suite_options'] || []
          end
        end

        def suite_options_list
          options[:suite_options].keys.map do |option_key|
            option_id = resolve_suite_option_key(option_key)
            { id: option_id, value: resolve_suite_option_value(option_id, options[:suite_options][option_key]) }
          end
        end

        def resolve_suite_option_key(option_key)
          return option_key if suite_option_definitions.any? { |d| d['id'] == option_key }

          matched = suite_option_definitions.find { |d| d['title'] == option_key }
          if matched
            matched['id']
          else
            valid_options = suite_option_definitions.map { |d| "#{d['id']} (#{d['title']})" }.join(', ')
            puts JSON.pretty_generate({
                                        errors: "Unknown suite option '#{option_key}' for suite '#{suite_id}'. " \
                                                "Valid options: #{valid_options}"
                                      })
            exit(3)
          end
        end

        def resolve_suite_option_value(option_id, provided_value)
          provided_value = provided_value.to_s
          definition = suite_option_definitions.find { |d| d['id'] == option_id }
          list_options = definition&.fetch('list_options', nil)

          return provided_value if list_options.blank?
          return provided_value if list_options.any? { |o| o['value'] == provided_value }

          matched = list_options.find { |o| o['label'] == provided_value }
          if matched
            matched['value']
          else
            valid_options = list_options.map { |o| "#{o['value']} (#{o['label']})" }.join(', ')
            puts JSON.pretty_generate({
                                        errors: "Invalid value '#{provided_value}' for suite option '#{option_id}'. " \
                                                "Valid values: #{valid_options}"
                                      })
            exit(3)
          end
        end
      end
    end
  end
end
