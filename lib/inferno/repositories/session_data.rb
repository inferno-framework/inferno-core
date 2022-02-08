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
            update: { value: value }
          ).insert(
            id: "#{test_session_id}_#{name}",
            name: name,
            value: value,
            test_session_id: test_session_id
          )
      end

      def load(test_session_id:, name:, type: 'text')
        raw_value =
          self.class::Model
            .find(test_session_id: test_session_id, name: name.to_s.downcase)
            &.value

        case type.to_s
        when 'oauth_credentials'
          DSL::OAuthCredentials.new(JSON.parse(raw_value || '{}'))
        else
          raw_value
        end
      end

      def get_all_from_session(test_session_id)
        self.class::Model
          .where(test_session_id: test_session_id)
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
        when 'oauth_credentials'
          credentials =
            if params[:value].is_a? String
              DSL::OAuthCredentials.new(JSON.parse(params[:value]))
            elsif !params[:value].is_a? DSL::OAuthCredentials
              raise Exceptions::BadSessionDataType.new(params[:name], DSL::OAuthCredentials, params[:value].class)
            else
              params[:value]
            end

          credentials.name = params[:name]
          credentials.to_s
        else
          raise Exceptions::UnknownSessionDataType, params
        end
      end

      class Model < Sequel::Model(db)
        many_to_one :test_session, class: 'Inferno::Repositories::TestSessions::Model', key: :test_session_id
      end
    end
  end
end
