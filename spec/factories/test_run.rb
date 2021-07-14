FactoryBot.define do
  factory :test_run, class: 'Inferno::Entities::TestRun' do
    test_session
    test_session_id { test_session.id }

    transient do
      runnable { { test_suite_id: 'BasicTestSuite::Suite' } }
    end

    test_suite_id { runnable[:test_suite_id] }
    test_group_id { runnable[:test_group_id] }
    test_id { runnable[:test_id] }

    inputs { nil }
    wait_timeout { nil }

    initialize_with { new(**attributes) }

    to_create do |instance|
      Inferno::Repositories::TestRuns.new.create(instance.to_hash).tap(&:runnable)
    end
  end
end
