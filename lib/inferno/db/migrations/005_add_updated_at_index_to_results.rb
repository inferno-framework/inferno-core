Sequel.migration do
  change do
    add_index :results, [:test_run_id, :updated_at]
  end
end
