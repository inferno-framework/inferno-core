Sequel.migration do
  change do
    create_table :requests_results do
      # using results_id instead of result_id to avoid ambiguous column error
      foreign_key :results_id, :results, index: true, type: String, null: false, size: 255
      foreign_key :requests_id, :requests, index: true, type: Integer, null: false, size: 255
    end
  end
end
