Sequel.migration do
  change do
    create_table :tags do
      column :id, String, primary_key: true, null: false, size: 36
      column :name, String, size: 255, null: false

      index :name, unique: true
    end

    create_table :requests_tags do
      foreign_key :tags_id, :tags, index: true, type: String, null: false, size: 36, key: [:id]
      foreign_key :requests_id, :requests, index: true, type: Integer, null: false, key: [:index]

      index [:tags_id, :requests_id], unique: true
      index [:requests_id, :tags_id], unique: true
    end
  end
end
