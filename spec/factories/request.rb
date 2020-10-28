FactoryBot.define do
  factory :request, class: 'Inferno::Entities::Request' do
    transient do
      result
      header_count { 2 }
    end

    result_id { result.id }

    verb { 'get' }
    url { 'http://www.example.com' }
    name { nil }
    status { 200 }
    direction { 'outgoing' }

    request_body { nil }

    sequence(:response_body) { |n| "RESPONSE_BODY #{n}" }

    test_session_id { result.test_session_id }

    initialize_with { new(**attributes) }

    to_create do |instance|
      Inferno::Repositories::Requests.new.create(instance.to_hash)
    end

    after(:create) do |instance, evaluator|
      instance.instance_variable_set(
        :@headers,
        repo_create_list(:header, evaluator.header_count, request_id: instance.index)
      )
    end
  end
end
