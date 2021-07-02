Sequel.migration do
  change do
    add_column :test_runs, :identifier, String, text: true
    add_index :test_runs, [:status, :identifier, :updated_at], concurrently: true
  end
end
