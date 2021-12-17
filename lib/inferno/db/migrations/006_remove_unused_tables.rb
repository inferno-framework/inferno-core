Sequel.migration do
  change do
    drop_table :result_outputs
    drop_table :result_prompt_values
  end
end
