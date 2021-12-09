Sequel.migration do
  change do
    # A way for the test to signal that it requires some kind of action by the
    # app that is invoking the test (e.g. SMART Launch, perhaps mid-test manual verification)
    # create_table :test_prompts do
    # end

    # For a given prompt, the tests specify what fields are associated (e.g redirect uri),
    # Those get filled out and stored within the run
    # create_table :test_prompt_field do
    # end

    create_table :test_sessions do
      column :id, String, primary_key: true, null: false
      column :test_suite_id, String

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end

    create_table :test_runs do
      column :id, String, primary_key: true, null: false
      column :status, String
      foreign_key :test_session_id, :test_sessions, index: true, type: String
      index [:test_session_id, :status] # Searching by unfinished test runs seems like it will be a likely query

      column :test_suite_id, String, index: true
      column :test_group_id, String, index: true
      column :test_id, String, index: true

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end

    create_table :test_run_inputs do
      column :id, String, primary_key: true, null: false
      foreign_key :test_run_id, :test_runs, index: true, type: String
      column :test_input_id, String
      column :value, String

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end

    create_table :results do
      column :id, String, primary_key: true, null: false

      foreign_key :test_run_id, :test_runs, index: true, type: String
      foreign_key :test_session_id, :test_sessions, index: true, type: String

      column :result, String
      column :result_message, String

      column :test_suite_id, String
      column :test_group_id, String
      column :test_id, String

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end

    create_table :result_inputs do
      column :id, String, primary_key: true, null: false
      foreign_key :result_id, :results, index: true, type: String
      column :test_input_id, String
      column :value, String

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end

    create_table :result_outputs do
      column :id, String, primary_key: true, null: false
      foreign_key :result_id, :results, index: true, type: String
      column :test_output_id, String
      column :value, String

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end

    create_table :result_prompt_values do
      column :id, String, primary_key: true, null: false

      foreign_key :result_id, :results, index: true, type: String

      column :test_prompt_id, String, null: false
      column :value, String, null: false

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end

    create_table :messages do
      primary_key :index
      column :id, String, index: true, null: false
      foreign_key :result_id, :results, index: true, type: String
      column :type, String
      column :message, String

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end

    create_table :requests do
      primary_key :index
      column :id, String, index: true, null: false
      column :verb, String
      column :url, String
      column :direction, String
      column :status, Integer
      column :name, String
      column :request_body, String, text: true
      column :response_body, String, text: true # It would be nice if we could store this on disk

      # Requires requests to be a part of tests now.
      foreign_key :result_id, :results, index: true, type: String
      foreign_key :test_session_id, :test_sessions, index: true, type: String
      index [:test_session_id, :name], concurrently: true

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end

    create_table :headers do
      column :id, String, index: true, null: false
      foreign_key :request_id, :requests, index: true, type: String
      column :type, String # request / response
      column :name, String
      column :value, String

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end

    create_table :session_data do
      column :id, String, index: true, null: false
      foreign_key :test_session_id, :test_sessions, index: true, type: String
      column :name, String
      column :value, String
      index [:test_session_id, :name]
    end
  end
end
