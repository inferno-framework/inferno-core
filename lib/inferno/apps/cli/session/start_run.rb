require 'faraday'
require_relative 'connection'
require_relative 'errors'

module Inferno
  module CLI
    module Session
      class StartRun
        include Connection
        include Errors
        attr_accessor :session_id, :options

        def initialize(session_id, options)
          self.session_id = session_id
          self.options = options
        end

        def run
          request_body = {
            test_session_id: session_id,
            "#{target_runnable_key}": target_runnable_id,
            inputs: runnable_inputs
          }

          response = connection.post('api/test_runs', request_body.to_json, content_type: 'application/json')

          handle_web_api_error(response, :start_run) if response.status != 200

          puts JSON.pretty_generate(JSON.parse(response.body))
          exit(0)
        end

        def session_details
          @session_details ||= begin
            response = connection.get("api/test_sessions/#{session_id}", nil, content_type: 'application/json')
            handle_web_api_error(response, :session_details) if response.status != 200
            JSON.parse(response.body)
          end
        end

        def target_runnable_details
          @target_runnable_details ||= find_target_runnable
        end

        def target_runnable_key
          if target_runnable_details.key?('suite_summary')
            'test_suite_id'
          elsif target_runnable_details.key?('run_as_group')
            'test_group_id'
          else
            'test_id'
          end
        end

        def target_runnable_id
          target_runnable_details['id']
        end

        def session_inputs
          @session_inputs ||= begin
            response = connection.get("api/test_sessions/#{session_id}/session_data", nil,
                                      content_type: 'application/json')
            handle_web_api_error(response, :session_data) if response.status != 200
            JSON.parse(response.body)
          end
        end

        def user_inputs
          @user_inputs ||= options[:inputs] || {}
        end

        def runnable_inputs
          @runnable_inputs ||= calculate_inputs
        end

        # runnable_to_find can be a complete internal id, an internal id suffix, or short id displayed in the UI
        def find_target_runnable
          target_runnable = options[:runnable].present? ? options[:runnable] : session_details['test_suite_id']
          target_runnable.to_s unless target_runnable.is_a?(String)

          candidates = []
          runnable_search(session_details['test_suite'], target_runnable, candidates)
          if candidates.blank?
            error_object =
              { errors: "Runnable '#{target_runnable}' not found in suite '#{session_details['test_suite_id']}'" }
            puts error_object.to_json
            exit(3)
          elsif candidates.size > 1
            error_object =
              { errors: "Runnable '#{target_runnable}' not unique in suite '#{session_details['test_suite_id']}'" }
            puts error_object.to_json
            exit(3)
          end

          candidates.first
        end

        def runnable_search(runnable_details, runnable_to_find, matches)
          matches << runnable_details if runnable_matches?(runnable_details, runnable_to_find)
          runnable_details['test_groups']&.each { |group| runnable_search(group, runnable_to_find, matches) }
          runnable_details['tests']&.each { |test| runnable_search(test, runnable_to_find, matches) }
        end

        def runnable_matches?(runnable_details, runnable_to_find)
          runnable_details['id'] == runnable_to_find ||
            runnable_details['id']&.ends_with?("-#{runnable_to_find}") ||
            runnable_details['short_id'] == runnable_to_find
        end

        # trying to replicate the process used in the UI
        def calculate_inputs
          target_runnable_details['inputs'].map do |runnable_input|
            input_run_value(runnable_input)
          end
        end

        def input_run_value(runnable_input)
          input_name = runnable_input['name']
          value = session_value_for_input(session_inputs, input_name)
          value = user_inputs[input_name] if user_inputs[input_name].present?
          value = runnable_input['default'] if value == '' && runnable_input['default'].present?
          if runnable_input['type'] == 'auth_info'
            component_object = value == '' ? {} : JSON.parse(value)
            add_auth_info_component_defaults(component_object, runnable_input)
            value = component_object.to_json
          end

          { 'name' => input_name, 'value' => value }
        end

        def session_value_for_input(session_inputs, input_name)
          session_input = session_inputs.find { |input| input['name'] == input_name }
          session_input&.dig('value') || ''
        end

        def add_auth_info_component_defaults(component_object, runnable_input)
          default_from_runnable_components(component_object, runnable_input)
          default_component_from_definitions(component_object, auth_info_mode_from_runnable_input(runnable_input))
        end

        def auth_info_mode_from_runnable_input(runnable_input)
          mode = runnable_input.dig('options', 'mode')
          if mode.nil?
            'access'
          elsif ['access', 'auth'].include?(mode)
            mode
          else
            "Failed to create run: unknown auth_info mode '#{mode}'."
          end
        end

        def default_component_from_definitions(component_object, mode)
          if component_object['auth_type'].blank? || component_object['auth_type'] == ''
            component_object['auth_type'] = 'public'
          end
          auth_type = component_object['auth_type']
          components_to_default = components_to_default(mode)

          components_to_default.each do |component|
            default_value = default_from_auth_info_component_definition(component, mode, auth_type)
            if (component_object[component].blank? || component_object[component] == '') && !default_value.blank?
              component_object[component] = default_value
            end
          end
        end

        def default_from_runnable_components(component_object, runnable_input)
          runnable_input.dig('options', 'components')&.each do |component|
            component_name = component['name']
            unless component_object.key?(component_name) || component['default'].blank?
              component_object[component_name] = component['default']
            end
          end
        end

        AUTH_INFO_COMPONENT_AUTH_MODE_DEFAULTS = {
          'use_discovery' => 'true',
          'pkce_support' => 'enabled',
          'pkce_code_challenge_method' => 'S256',
          'auth_request_method' => 'GET'
        }.freeze

        AUTH_INFO_COMPONENT_ACCESS_MODE_DEFAULTS = {
          'access_token' => '',
          'refresh_token' => '',
          'issue_time' => '',
          'expires_in' => ''
        }.freeze

        def components_to_default(mode)
          components_to_default =
            case mode
            when 'access'
              AUTH_INFO_COMPONENT_ACCESS_MODE_DEFAULTS.keys
            when 'auth'
              AUTH_INFO_COMPONENT_AUTH_MODE_DEFAULTS.keys
            end
          components_to_default << 'encryption_algorithm'

          components_to_default
        end

        def default_from_auth_info_component_definition(component, mode, auth_type)
          return 'public' if component == 'auth_type'
          return 'ES384' if component == 'encryption_algorithm' && ['backend_services',
                                                                    'asymmetric'].include?(auth_type)

          case mode
          when 'auth'
            AUTH_INFO_COMPONENT_AUTH_MODE_DEFAULTS[component]
          when 'access'
            AUTH_INFO_COMPONENT_ACCESS_MODE_DEFAULTS[component]
          end
        end
      end
    end
  end
end
