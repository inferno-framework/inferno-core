module Inferno
  module Repositories
    class Messages < Repository
      def messages_for_result(result_id)
        self.class::Model
          .order(:index)
          .where(result_id: result_id)
          .to_a
          .map!(&:to_json_data)
          .each(&:deep_symbolize_keys!)
          .map! { |result| build_entity(result) }
      end

      class Model < Sequel::Model(db)
        many_to_one :result, class: 'Inferno::Repositories::Results::Model', key: :result_id

        def before_create
          self.id = SecureRandom.uuid
          time = Time.now
          self.created_at ||= time
          self.updated_at ||= time
          super
        end

        def validate
          super
          types = Entities::Message::TYPES
          errors.add(:message, 'must be present') if message.blank?
          errors.add(:type, 'must be present') if type.blank?
          errors.add(:type, "'#{type}' is invalid. Must be one of: #{types.join(', ')}") unless types.include?(type)
        end
      end
    end
  end
end
