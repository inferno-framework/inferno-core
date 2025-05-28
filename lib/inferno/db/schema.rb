Sequel.migration do
  change do
    create_table(:schema_info) do
      Integer :version, :default=>0, :null=>false
    end
    
    create_table(:tags, :ignore_index_errors=>true) do
      String :id, :size=>36, :null=>false
      String :name, :size=>255, :null=>false
      
      primary_key [:id]
      
      index [:name], :unique=>true
    end
    
    create_table(:test_sessions) do
      String :id, :size=>255, :null=>false
      String :test_suite_id, :size=>255, :null=>false
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      String :suite_options, :text=>true
      
      primary_key [:id]
    end
    
    create_table(:validator_sessions, :ignore_index_errors=>true) do
      String :id, :size=>36, :null=>false
      String :validator_session_id, :size=>255, :null=>false
      String :test_suite_id, :size=>255, :null=>false
      String :validator_name, :size=>255, :null=>false
      String :suite_options, :text=>true
      DateTime :last_accessed, :null=>false
      
      primary_key [:id]
      
      index [:test_suite_id, :validator_name, :suite_options], :unique=>true
      index [:validator_session_id], :unique=>true
    end
    
    create_table(:session_data, :ignore_index_errors=>true) do
      String :id, :size=>255, :null=>false
      foreign_key :test_session_id, :test_sessions, :type=>String, :size=>255, :null=>false
      String :name, :size=>255, :null=>false
      String :value, :text=>true
      
      index [:id], :unique=>true
      index [:test_session_id]
      index [:test_session_id, :name], :unique=>true
    end
    
    create_table(:test_runs, :ignore_index_errors=>true) do
      String :id, :size=>255, :null=>false
      String :status, :size=>255
      foreign_key :test_session_id, :test_sessions, :type=>String, :size=>255
      String :test_suite_id, :size=>255
      String :test_group_id, :size=>255
      String :test_id, :size=>255
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      String :identifier, :text=>true
      DateTime :wait_timeout
      
      primary_key [:id]
      
      index [:status, :identifier, :wait_timeout, :updated_at]
      index [:test_group_id]
      index [:test_id]
      index [:test_session_id]
      index [:test_session_id, :status]
      index [:test_suite_id]
    end
    
    create_table(:results, :ignore_index_errors=>true) do
      String :id, :size=>255, :null=>false
      foreign_key :test_run_id, :test_runs, :type=>String, :size=>255, :null=>false
      foreign_key :test_session_id, :test_sessions, :type=>String, :size=>255, :null=>false
      String :result, :size=>255
      String :result_message, :size=>255
      String :test_suite_id, :size=>255
      String :test_group_id, :size=>255
      String :test_id, :size=>255
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      String :input_json, :text=>true
      String :output_json, :text=>true
      
      primary_key [:id]
      
      index [:test_run_id]
      index [:test_run_id, :updated_at]
      index [:test_session_id]
      index [:test_session_id, :test_group_id]
      index [:test_session_id, :test_id]
      index [:test_session_id, :test_suite_id]
    end
    
    create_table(:messages, :ignore_index_errors=>true) do
      primary_key :index
      String :id, :size=>255, :null=>false
      foreign_key :result_id, :results, :type=>String, :size=>255, :null=>false
      String :type, :size=>255, :null=>false
      String :message, :size=>255, :null=>false
      
      index [:id]
      index [:result_id]
    end
    
    create_table(:requests, :ignore_index_errors=>true) do
      primary_key :index
      String :id, :size=>255, :null=>false
      String :verb, :size=>255, :null=>false
      String :url, :size=>255, :null=>false
      String :direction, :size=>255, :null=>false
      Integer :status
      String :name, :size=>255
      String :request_body, :text=>true
      String :response_body, :text=>true
      foreign_key :result_id, :results, :type=>String, :size=>255, :null=>false
      foreign_key :test_session_id, :test_sessions, :type=>String, :size=>255, :null=>false
      String :"[:test_session_id, :name]"
      DateTime :created_at, :null=>false
      DateTime :updated_at, :null=>false
      
      index [:id]
      index [:result_id]
      index [:test_session_id]
    end
    
    create_table(:headers, :ignore_index_errors=>true) do
      String :id, :size=>255, :null=>false
      foreign_key :request_id, :requests, :type=>String, :size=>255, :null=>false
      String :type, :size=>255, :null=>false
      String :name, :size=>255, :null=>false
      String :value, :size=>255
      
      index [:id]
      index [:request_id]
    end
    
    create_table(:requests_results, :ignore_index_errors=>true) do
      foreign_key :results_id, :results, :type=>String, :size=>255, :null=>false
      foreign_key :requests_id, :requests, :type=>String, :size=>255, :null=>false
      
      index [:requests_id]
      index [:results_id]
    end
    
    create_table(:requests_tags, :ignore_index_errors=>true) do
      foreign_key :tags_id, :tags, :type=>String, :size=>36, :null=>false, :key=>[:id]
      foreign_key :requests_id, :requests, :null=>false, :key=>[:index]
      
      index [:requests_id]
      index [:requests_id, :tags_id], :unique=>true
      index [:tags_id]
      index [:tags_id, :requests_id], :unique=>true
    end
  end
end
