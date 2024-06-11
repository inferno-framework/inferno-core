require_relative '../dsl/auth_info'
require_relative '../dsl/oauth_credentials'

module Inferno
  module Repositories
    class SessionData < Repository
      def save(params)
        name = params[:name].to_s.downcase
        test_session_id = params[:test_session_id]

        value = value_to_persist(params)

        db
          .insert_conflict(
            target: :id,
            update: { value: }
          ).insert(
            id: "#{test_session_id}_#{name}",
            name:,
            value:,
            test_session_id:
          )
      end

      def load(test_session_id:, name:, type: 'text')
        raw_value =
          self.class::Model
            .find(test_session_id:, name: name.to_s.downcase)
            &.value

        case type.to_s
        when 'oauth_credentials'
          DSL::OAuthCredentials.new(JSON.parse(raw_value || '{}'))
        when 'checkbox'
          JSON.parse(raw_value || '[]')
        when 'auth_info'
          DSL::AuthInfo.new(JSON.parse(raw_value || '{}'))
        else
          raw_value
        end
      end

      def get_all_from_session(test_session_id)
        self.class::Model
          .where(test_session_id:)
          .all
          .map! do |session_data_hash|
            build_entity(
              session_data_hash
                .to_json_data
                .deep_symbolize_keys!
            )
          end
      end

      def entity_class_name
        'SessionData'
      end

      def value_to_persist(params)
        return nil if params[:value].blank?

        case params[:type]&.to_s
        when 'text', 'textarea', 'radio'
          params[:value].to_s
        when 'checkbox'
          serialize_checkbox_input(params)
        when 'oauth_credentials'
          serialize_oauth_credentials_input(params)
        when 'auth'
          serialize_auth_info(params)
        else
          raise Exceptions::UnknownSessionDataType, params
        end
      end

      def serialize_checkbox_input(params)
        if params[:value].is_a?(String)
          params[:value]
        elsif params[:value].nil?
          '[]'
        elsif params[:value].is_a?(Array)
          params[:value].to_json
        else
          raise Exceptions::BadSessionDataType.new(
            params[:name],
            'JSON String or Array',
            params[:value].class
          )
        end
      end

      def serialize_oauth_credentials_input(params)
        credentials =
          if params[:value].is_a? String
            DSL::OAuthCredentials.new(JSON.parse(params[:value]))
          elsif !params[:value].is_a? DSL::OAuthCredentials
            raise Exceptions::BadSessionDataType.new(
              params[:name],
              DSL::OAuthCredentials.name,
              params[:value].class
            )
          else
            params[:value]
          end

        credentials.name = params[:name]
        credentials.to_s
      end

      def serialize_auth_info(params)
        auth =
          if params[:value].is_a? String
            DSL::AuthInfo.new(JSON.parse(params[:value]))
          elsif !params[:value].is_a? DSL::AuthInfo
            raise Exceptions::BadSessionDataType.new(
              params[:name],
              DSL::AuthInfo.name,
              params[:value].class
            )
          else
            params[:value]
          end

        auth.name = params[:name]
        auth.to_s
      end

      class Model < Sequel::Model(db)
        many_to_one :test_session, class: 'Inferno::Repositories::TestSessions::Model', key: :test_session_id
      end
    end
  end
end
