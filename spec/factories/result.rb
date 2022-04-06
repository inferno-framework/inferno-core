FactoryBot.define do
  factory :result, class: 'Inferno::Entities::Result' do
    transient do
      runnable { test_run.runnable.reference_hash }
      test_run { repo_create(:test_run) }
      test_session { test_run.test_session }
      message_count { 0 }
      request_count { 0 }
    end

    test_session_id { test_session.id }
    test_run_id { test_run.id }

    test_suite_id { runnable[:test_suite_id] }
    test_group_id { runnable[:test_group_id] }
    test_id { runnable[:test_id] }
    output_json { '[]' }
    input_json { '[]' }

    result { 'pass' }

    initialize_with { new(**attributes) }

    before(:create) do |instance, evaluator|
      instance.instance_variable_set(
        :@requests,
        build_list(:request, evaluator.request_count, result: instance)
      )
    end

    to_create do |instance|
      Inferno::Repositories::Results.new.create(instance.to_hash)
    end

    after(:create) do |instance, evaluator|
      instance.instance_variable_set(
        :@messages,
        repo_create_list(:message, evaluator.message_count, result_id: instance.id)
      )
      instance.instance_variable_set(
        :@requests,
        repo_create_list(:request, evaluator.request_count, result_id: instance.id)
      )
    end
  end
end
