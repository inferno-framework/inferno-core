Sequel.migration do
  change do
    drop_table :test_run_inputs
    drop_table :result_inputs

    set_column_type :session_data, :value, String, text: true
    drop_index :session_data, [:test_session_id, :name], concurrently: true
    add_index :session_data, [:test_session_id, :name], unique: true, concurrently: true
    drop_index :session_data, :id, concurrently: true
    add_index :session_data, :id, unique: true, concurrently: true

    add_column :results, :input_json, String, text: true
    add_column :results, :output_json, String, text: true
    add_index :results, [:test_session_id, :test_id], concurrently: true
    add_index :results, [:test_session_id, :test_group_id], concurrently: true
    add_index :results, [:test_session_id, :test_suite_id], concurrently: true
  end
end
