FactoryBot.define do
  factory :header, class: 'Inferno::Entities::Header' do
    request

    request_id { request.index }

    sequence(:name) { |n| "HEADER NAME #{n}" }

    sequence(:value) { |n| "HEADER VALUE #{n}" }

    sequence(:type) { |n| n.even? ? 'request' : 'response' }

    initialize_with { new(**attributes) }

    to_create do |instance|
      Inferno::Repositories::Headers.new.create(instance.to_hash)
    end
  end
end
