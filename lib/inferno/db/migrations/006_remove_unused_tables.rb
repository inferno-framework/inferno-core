Sequel.migration do
  change do
    drop_table :result_outputs
    drop_table :result_prompt_values

    alter_table(:test_sessions) { set_column_not_null :test_suite_id }

    alter_table(:results) do
      set_column_not_null :test_run_id
      set_column_not_null :test_session_id
    end

    alter_table(:messages) do
      set_column_not_null :result_id
      set_column_not_null :type
      set_column_not_null :message
    end

    alter_table(:requests) do
      set_column_not_null :verb
      set_column_not_null :url
      set_column_not_null :direction
      set_column_not_null :result_id
      set_column_not_null :test_session_id
    end

    alter_table(:headers) do
      set_column_not_null :request_id
      set_column_not_null :type
      set_column_not_null :name
    end

    alter_table(:session_data) do
      set_column_not_null :test_session_id
      set_column_not_null :name
    end
  end
end
