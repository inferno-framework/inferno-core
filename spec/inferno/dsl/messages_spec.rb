require_relative '../../../lib/inferno/exceptions'
RSpec.describe Inferno::DSL::Messages do
  let(:klass) do
    Class.new(Inferno::Entities::Test).new
  end

  describe '#error_messages?' do
    it 'returns false if no messages' do
      expect(klass.error_messages?).to be(false)
    end

    it 'returns false if no messages using a custom list' do
      expect(klass.error_messages?(message_list: [])).to be(false)
    end

    it 'returns false if only warning and info messages' do
      klass.add_message('info', 'this is not an error')
      klass.add_message('warning', 'this is also not an error')
      expect(klass.error_messages?).to be(false)
    end

    it 'returns true if an error message present' do
      klass.add_message('info', 'this is not an error')
      klass.add_message('error', 'this is an error')
      expect(klass.error_messages?).to be(true)
    end
  end

  describe '#add_message' do
    it 'adds a message with the given type and content' do
      klass.add_message('info', 'hello world')
      expect(klass.messages).to include({ type: 'info', message: 'hello world' })
    end

    it 'coerces the type to a string' do
      klass.add_message(:warning, 'watch out')
      expect(klass.messages.first[:type]).to eq('warning')
    end

    it 'strips consistent leading spaces from the message' do
      klass.add_message('error', " - line1\n - line2")
      expect(klass.messages.first[:message]).to eq("- line1\n- line2")
    end
  end

  describe '#info' do
    it 'adds an info message when given a string' do
      klass.info('some info')
      expect(klass.messages).to include({ type: 'info', message: 'some info' })
    end

    it 'does nothing when called with no arguments and no block' do
      klass.info
      expect(klass.messages).to be_empty
    end

    it 'does not raise when the block passes' do
      expect { klass.info { true } }.to_not raise_error
      expect(klass.messages).to be_empty
    end

    it 'converts a failed assertion in a block to an info message' do
      klass.info { raise Inferno::Exceptions::AssertionException, 'bad thing happened' }
      expect(klass.messages).to include({ type: 'info', message: 'bad thing happened' })
    end

    it 'does not suppress non-assertion exceptions from a block' do
      expect { klass.info { raise 'unexpected' } }.to raise_error(RuntimeError, 'unexpected')
    end
  end

  describe '#warning' do
    it 'adds a warning message when given a string' do
      klass.warning('watch out')
      expect(klass.messages).to include({ type: 'warning', message: 'watch out' })
    end

    it 'does nothing when called with no arguments and no block' do
      klass.warning
      expect(klass.messages).to be_empty
    end

    it 'does not raise when the block passes' do
      expect { klass.warning { true } }.to_not raise_error
      expect(klass.messages).to be_empty
    end

    it 'converts a failed assertion in a block to a warning message' do
      klass.warning { raise Inferno::Exceptions::AssertionException, 'risky thing happened' }
      expect(klass.messages).to include({ type: 'warning', message: 'risky thing happened' })
    end

    it 'does not suppress non-assertion exceptions from a block' do
      expect { klass.warning { raise 'unexpected' } }.to raise_error(RuntimeError, 'unexpected')
    end
  end
end
