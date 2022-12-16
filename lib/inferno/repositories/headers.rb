module Inferno
  module Repositories
    class Headers < Repository
      def self.table_name
        :unique_headers
      end

      class Model < Sequel::Model(db)
        many_to_many :request,
                     class: 'Inferno::Repositories::Requests::Model',
                     join_table: :requests_unique_headers,
                     left_key: :unique_headers_id,
                     right_key: :requests_id

        def before_create
          self.id = SecureRandom.uuid
          super
        end
      end
    end
  end
end
