require_relative '../../lib/inferno/repositories'

FactoryBot.define do
  factory :test_session, class: 'Inferno::Entities::TestSession' do
    test_suite_id { 'BasicTestSuite::Suite' }

    initialize_with { new(**attributes) }

    to_create { |instance| Inferno::Repositories::TestSessions.new.create(instance.to_hash) }
  end
end
