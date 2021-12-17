Sequel.migration do
  change do
    add_column :test_runs, :identifier, String, text: true, size: 255
    add_column :test_runs, :wait_timeout, DateTime
    add_index :test_runs, [:status, :identifier, :wait_timeout, :updated_at]
  end
end
