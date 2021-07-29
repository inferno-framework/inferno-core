Sequel.migration do
  change do
    create_table :requests_results do
      # using results_id instead of result_id to avoid ambiguous column error
      foreign_key :results_id, :results, index: true, type: String, null: false
      foreign_key :requests_id, :requests, index: true, type: String, null: false
    end
  end
end
