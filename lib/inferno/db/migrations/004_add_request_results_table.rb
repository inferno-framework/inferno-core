Sequel.migration do
  change do
    create_table :requests_results do
      foreign_key :result_id, :results, index: true, type: String, null: false
      foreign_key :request_id, :requests, index: true, type: String, null: false
    end
  end
end
