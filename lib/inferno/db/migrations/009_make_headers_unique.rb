Sequel.migration do
  change do
    create_table :unique_headers do
      column :id, String, primary_key: true, null: false, size: 36
      column :type, String, size: 10 # request / response
      column :name, String, size: 255
      column :value, String, text: true

      index [:type, :name, :value], unique: true
    end

    create_table :requests_unique_headers do
      foreign_key :unique_headers_id, :unique_headers, index: true, type: String, null: false, size: 36, key: [:id]
      foreign_key :requests_id, :requests, index: true, type: Integer, null: false, size: 36, key: [:index]
      index [:requests_id, :unique_headers_id], unique: true
    end

    headers_table = self[:headers]
    unique_headers_table = self[:unique_headers]
    join_table = self[:requests_unique_headers]

    headers_table.order(:id).paged_each do |header|
      type = header[:type]
      name = header[:name]
      value = header[:value]
      request_id = header[:request_id]

      unique_header_id = unique_headers_table.where(type:, name:, value:).get(:id)

      if unique_header_id.blank?
        unique_header_id = SecureRandom.uuid
        unique_headers_table.insert(id: unique_header_id, type:, name:, value:)
      end

      join_table.insert(requests_id: request_id, unique_headers_id: unique_header_id)
    end

    drop_table :headers
  end
end
