Sequel.migration do
  change do
    drop_column :headers, :created_at
    drop_column :headers, :updated_at

    drop_column :messages, :created_at
    drop_column :messages, :updated_at
  end
end
