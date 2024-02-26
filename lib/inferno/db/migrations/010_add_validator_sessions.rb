Sequel.migration do
  change do
    create_table :validator_sessions do
      column :id, String, primary_key: true, null: false, size: 36
      column :validator_session_id,  String, null: false, size: 255#, unique: true
      column :test_suite_id, String, null: false, size: 255
      column :validator_name, String, null: false, size: 255
      column :suite_options, String, text: true
      column :last_accessed, DateTime, null: false
      index [:validator_session_id], unique: true
      index [:test_suite_id, :validator_name, :suite_options], unique: true
    end
  end
end
