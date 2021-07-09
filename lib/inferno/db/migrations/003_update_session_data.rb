Sequel.migration do
  change do
    drop_table :test_run_inputs
    drop_table :result_inputs

    set_column_type :session_data, :value, String, text: true
    add_column :session_data, :created_at, DateTime, null: false
    add_column :session_data, :updated_at, DateTime, null: false
    add_column :results, :input_json, String, text: true
    add_column :results, :output_json, String, text: true
  end
end
