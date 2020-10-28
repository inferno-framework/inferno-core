module Inferno
  module Repositories
    class Headers < Repository
      class Model < Sequel::Model(db)
        many_to_one :request, class: 'Inferno::Repositories::Requests::Model', key: :request_id

        def before_create
          self.id = SecureRandom.uuid
          time = Time.now
          self.created_at ||= time
          self.updated_at ||= time
          super
        end

        def validate
          super
          errors.add(:request_id, 'must be present') if request_id.blank?
        end
      end
    end
  end
end
