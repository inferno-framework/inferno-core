require 'faraday'
require_relative 'connection'
require_relative 'errors'

module Inferno
  module CLI
    module Session
      class CreateSession
        include Connection
        include Errors

        attr_accessor :options
        attr_reader :suite

        def initialize(suite, options)
          @suite = suite
          self.options = options
        end

        def run
          puts JSON.pretty_generate(create_session)
          exit(0)
        end

        def create_session
          request_body = { test_suite_id: suite_id }
          request_body[:preset_id] = preset_id if options[:preset].present?
          request_body[:suite_options] = suite_options_list if options[:suite_options].present?

          response = post('api/test_sessions', request_body.to_json, content_type: 'application/json')

          handle_web_api_error(response, :session_create) if response.status != 200

          JSON.parse(response.body)
        end

        def suite_id
          @suite_id ||= resolve_suite_identifier
        end

        def all_suite_definitions
          @all_suite_definitions ||= begin
            response = get('api/test_suites')
            if response.status != 200
              puts JSON.pretty_generate({ errors: "Could not fetch test suites list from '#{base_url}'" })
              exit(3)
            end
            JSON.parse(response.body)
          end
        end

        def resolve_suite_identifier
          matched = all_suite_definitions.find { |s| s['id'] == suite }
          return matched['id'] if matched.present?

          matched = all_suite_definitions.find { |s| s['title'] == suite || s['short_title'] == suite }
          return matched['id'] if matched.present?

          valid_suites = all_suite_definitions.map { |s| "#{s['id']} (#{s['title']})" }.join(', ')
          puts JSON.pretty_generate(
            { errors: "Suite '#{suite}' not found. Valid suites: #{valid_suites}" }
          )
          exit(3)
        end

        def preset_id
          @preset_id ||= resolve_preset_identifier
        end

        def suite_presets
          suite_def = all_suite_definitions.find { |s| s['id'] == suite_id }
          suite_def&.fetch('presets', []) || []
        end

        def resolve_preset_identifier
          return unless options[:preset].present?

          preset = options[:preset]
          return preset if suite_presets.any? { |p| p['id'] == preset }

          matched = suite_presets.find { |p| p['title'] == preset }
          return matched['id'] if matched.present?

          valid_presets = suite_presets.map { |p| "#{p['id']} (#{p['title']})" }.join(', ')
          puts JSON.pretty_generate(
            { errors: "Preset '#{preset}' not found for suite '#{suite_id}'. Valid presets: #{valid_presets}" }
          )
          exit(3)
        end

        def suite_option_definitions
          suite_def = all_suite_definitions.find { |s| s['id'] == suite_id }
          suite_def&.fetch('suite_options', []) || []
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
          return matched['id'] if matched.present?

          valid_options = suite_option_definitions.map { |d| "#{d['id']} (#{d['title']})" }.join(', ')
          puts JSON.pretty_generate({
                                      errors: "Unknown suite option '#{option_key}' for suite '#{suite_id}'. " \
                                              "Valid options: #{valid_options}"
                                    })
          exit(3)
        end

        def resolve_suite_option_value(option_id, provided_value)
          provided_value = provided_value.to_s
          list_options = suite_option_list_options(option_id)

          return provided_value if list_options.blank?
          return provided_value if list_options.any? { |o| o['value'] == provided_value }

          resolve_suite_option_value_by_label(option_id, provided_value, list_options)
        end

        def suite_option_list_options(option_id)
          definition = suite_option_definitions.find { |d| d['id'] == option_id }
          definition&.fetch('list_options', nil)
        end

        def resolve_suite_option_value_by_label(option_id, provided_value, list_options)
          matched = list_options.find { |o| o['label'] == provided_value }
          return matched['value'] if matched

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
