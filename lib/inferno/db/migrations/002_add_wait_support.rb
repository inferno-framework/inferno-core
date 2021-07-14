Sequel.migration do
  change do
    add_column :test_runs, :identifier, String, text: true
    add_column :test_runs, :wait_timeout, DateTime
    add_index :test_runs, [:status, :identifier, :wait_timeout, :updated_at], concurrently: true
  end
end
