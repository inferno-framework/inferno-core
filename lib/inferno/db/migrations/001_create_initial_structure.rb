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
      column :id, String, primary_key: true, null: false, size: 36
      column :test_suite_id, String, size: 255

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end

    create_table :test_runs do
      column :id, String, primary_key: true, null: false, size: 36
      column :status, String, size: 255
      foreign_key :test_session_id, :test_sessions, index: true, type: String, size: 36, key: [:id]
      index [:test_session_id, :status] # Searching by unfinished test runs seems like it will be a likely query

      column :test_suite_id, String, index: true, size: 255
      column :test_group_id, String, index: true, size: 255
      column :test_id, String, index: true, size: 255

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end

    create_table :test_run_inputs do
      column :id, String, primary_key: true, null: false, size: 36
      foreign_key :test_run_id, :test_runs, index: true, type: String, key: [:id]
      column :test_input_id, String, size: 255
      column :value, String, text: true

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end

    create_table :results do
      column :id, String, primary_key: true, null: false, size: 36

      foreign_key :test_run_id, :test_runs, index: true, type: String, size: 36, key: [:id]
      foreign_key :test_session_id, :test_sessions, index: true, type: String, size: 36, key: [:id]

      column :result, String, size: 255
      column :result_message, String, text: true

      column :test_suite_id, String, size: 255
      column :test_group_id, String, size: 255
      column :test_id, String, size: 255

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end

    create_table :result_inputs do
      column :id, String, primary_key: true, null: false, size: 36
      foreign_key :result_id, :results, index: true, type: String, size: 36, key: [:id]
      column :test_input_id, String, size: 255
      column :value, String, text: true

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end

    create_table :result_outputs do
      column :id, String, primary_key: true, null: false, size: 36
      foreign_key :result_id, :results, index: true, type: String, size: 36, key: [:id]
      column :test_output_id, String, size: 255
      column :value, String, text: true

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end

    create_table :result_prompt_values do
      column :id, String, primary_key: true, null: false, size: 36

      foreign_key :result_id, :results, index: true, type: String, size: 36, key: [:id]

      column :test_prompt_id, String, null: false, size: 255
      column :value, String, null: false, text: true

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end

    create_table :messages do
      primary_key :index
      column :id, String, index: true, null: false, size: 36
      foreign_key :result_id, :results, index: true, type: String, size: 36, key: [:id]
      column :type, String, size: 255
      column :message, String, text: true

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end

    create_table :requests do
      primary_key :index
      column :id, String, null: false, size: 36
      column :verb, String, size: 255
      column :url, String, text: true
      column :direction, String, size: 255
      column :status, Integer
      column :name, String, size: 255
      column :request_body, String, text: true
      column :response_body, String, text: true # It would be nice if we could store this on disk
      index [:id], unique: true

      # Requires requests to be a part of tests now.
      foreign_key :result_id, :results, index: true, type: String, size: 36, key: [:id]
      foreign_key :test_session_id, :test_sessions, index: true, type: String, size: 36, key: [:id]
      index [:test_session_id, :name]



      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end

    create_table :headers do
      column :id, String, index: true, null: false, size: 36
      foreign_key :request_id, :requests, index: true, type: Integer, key: [:index]
      column :type, String, size: 255 # request / response
      column :name, String, size: 255
      column :value, String, text: true

      column :created_at, DateTime, null: false
      column :updated_at, DateTime, null: false
    end

    create_table :session_data do
      column :id, String, index: true, null: false, size: 255
      foreign_key :test_session_id, :test_sessions, index: true, type: String, size: 36, key: [:id]
      column :name, String, size: 255
      column :value, String, text: true
      index [:test_session_id, :name]
    end
  end
end
