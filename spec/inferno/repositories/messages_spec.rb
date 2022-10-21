RSpec.describe Inferno::Repositories::Messages do
  let(:repo) { described_class.new }

  describe '#create' do
    let(:result) { repo_create(:result) }
    let(:message_params) do
      {
        message: 'WARNING',
        type: 'warning',
        result_id: result.id
      }
    end

    it 'persists a message' do
      message = repo.create(message_params)

      expect(message).to be_a(Inferno::Entities::Message)

      message_params.each do |key, value|
        expect(message.send(key)).to eq(value)
      end
    end

    it 'raises an error if the message is blank' do
      invalid_params = message_params.merge(message: '')

      expect { repo.create(invalid_params) }.to raise_error(Sequel::ValidationFailed, /message/)

      message_params.delete(:message)

      expect { repo.create(message_params) }.to raise_error(Sequel::ValidationFailed, /message/)
    end

    it 'raises an error if the type is blank' do
      invalid_params = message_params.merge(type: '')

      expect { repo.create(invalid_params) }.to raise_error(Sequel::ValidationFailed, /type/)

      message_params.delete(:type)

      expect { repo.create(message_params) }.to raise_error(Sequel::ValidationFailed, /type/)
    end

    it 'raises an error if the type is invalid' do
      invalid_params = message_params.merge(type: 'abc')

      expect { repo.create(invalid_params) }.to raise_error(Sequel::ValidationFailed, /type/)
    end
  end

  describe '#messages_for_result' do
    let(:message_count) { 2 }
    let(:result) { repo_create(:result, message_count:) }

    it 'returns the messages for a result' do
      messages = repo.messages_for_result(result.id)

      expect(messages).to all(be_a(Inferno::Entities::Message))
      expect(messages.length).to eq(message_count)
    end

    it 'returns the messages in ascending order' do
      messages = repo.messages_for_result(result.id)

      messages.each_cons(2) do |message, next_message|
        expect(message.index).to be < next_message.index
      end
    end
  end
end
