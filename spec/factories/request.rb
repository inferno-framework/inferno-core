FactoryBot.define do
  factory :request, class: 'Inferno::Entities::Request' do
    transient do
      result { repo_create(:result, request_count: 0) }
      header_count { 2 }
    end

    result_id { result.id }

    verb { 'get' }
    url { 'http://www.example.com' }
    name { nil }
    status { 200 }
    direction { 'outgoing' }
    headers do
      [
        {
          type: 'request',
          name: 'Request-Header',
          value: 'REQUEST HEADER VALUE'
        },
        {
          type: 'response',
          name: 'Response-Header',
          value: 'RESPONSE HEADER VALUE'
        }
      ]
    end

    request_body { nil }

    sequence(:response_body) { |n| "RESPONSE_BODY #{n}" }

    test_session_id { result.test_session_id }

    initialize_with { new(**attributes) }

    to_create do |instance|
      Inferno::Repositories::Requests.new.create(instance.to_hash)
    end
  end
end
