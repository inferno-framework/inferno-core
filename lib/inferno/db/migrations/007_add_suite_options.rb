Sequel.migration do
  change do
    add_column :test_sessions, :suite_options, String, text: true, size: 255
  end
end
