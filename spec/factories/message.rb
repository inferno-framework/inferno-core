FactoryBot.define do
  factory :message, class: 'Inferno::Entities::Message' do
    result

    result_id { result.id }

    sequence(:message) { |n| "MESSAGE #{n}" }

    type { Inferno::Entities::Message::TYPES.sample }

    initialize_with { new(**attributes) }

    to_create do |instance|
      Inferno::Repositories::Messages.new.create(instance.to_hash)
    end
  end
end
