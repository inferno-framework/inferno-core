module Inferno
  module Repositories
    class Tags < Repository
      class Model < Sequel::Model(db)
        many_to_many :requests,
                     class: 'Inferno::Repositories::Requests::Model',
                     join_table: :requests_tags,
                     left_key: :tags_id,
                     right_key: :requests_id

        def before_create
          self.id = SecureRandom.uuid
          super
        end
      end
    end
  end
end
