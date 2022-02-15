RSpec.describe Inferno::Entities::TestSuite do
  let!(:suite_class) { Class.new(described_class) }

  describe '.group' do
    let!(:group_class) { Class.new(Inferno::Entities::TestGroup) }
    let(:title) { 'GROUP_TITLE' }
    let(:id) { 'GROUP_ID' }

    before do
      allow(Class).to receive(:new).with(Inferno::Entities::TestGroup).and_return(group_class)
    end

    context 'without arguments' do
      it 'adds an empty group to the suite' do
        suite_class.group

        expect(suite_class.groups.length).to eq(1)
        expect(suite_class.groups.first).to eq(group_class)
      end
    end

    context 'with a string argument' do
      it 'adds a group with the given title to the suite' do
        suite_class.group title

        expect(suite_class.groups.length).to eq(1)
        expect(suite_class.groups.first.title).to eq(title)
      end
    end

    context 'with a hash argument' do
      it 'adds a group with the metadata defined in the hash' do
        metadata = {
          title: title,
          id: id
        }

        suite_class.group metadata

        expect(suite_class.groups.length).to eq(1)

        expect(suite_class.groups.first.title).to eq(title)
        expect(suite_class.groups.first.id).to eq("#{suite_class.id}-#{id}")
      end
    end

    context 'with string and hash arguments' do
      it 'adds a group with a title from the string and other metadata from the hash' do
        metadata = { id: id }

        suite_class.group title, metadata

        expect(suite_class.groups.length).to eq(1)
        expect(suite_class.groups.first.title).to eq(title)

        expect(suite_class.groups.first.id).to eq("#{suite_class.id}-#{id}")
      end
    end

    context 'with a block argument' do
      it 'adds a group which evaluates that block' do
        suite_class.group do
          title 'TITLE'
          id 'ID'
        end

        expect(suite_class.groups.length).to eq(1)
        expect(suite_class.groups.first.title).to eq('TITLE')
        expect(suite_class.groups.first.id).to eq("#{suite_class.id}-ID")
      end
    end
  end

  describe '.test' do
    let(:test_class) { Class.new(Inferno::Entities::Test) }

    it 'adds a test to the default group in the default group' do
      allow(Class).to receive(:new).and_call_original
      allow(Class).to receive(:new).with(Inferno::Entities::Test).and_return(test_class)

      suite_class.test

      expect(suite_class.groups).to eq([suite_class.default_group])
      expect(suite_class.default_group.tests).to eq([test_class])
    end
  end

  describe '.version' do
    let(:test_suite) do
      suite_class.version 'VERSION'
      suite_class
    end

    specify 'it gets/sets the version' do
      expect(test_suite.version).to eq('VERSION')
    end
  end

  describe '.check_configuration' do
    it 'takes and stores a block' do
      initial_block = suite_class.instance_variable_get(:@check_configuration_block)
      expect(initial_block).to be_nil

      suite_class.check_configuration { 1 + 1 }
      new_block = suite_class.instance_variable_get(:@check_configuration_block)

      expect(new_block).to be_a(Proc)
    end
  end

  describe '.configuration_messages' do
    let(:messages) { [{ type: 'info', message: 'message' }] }

    context 'when an argument is provided' do
      it 'sets the configuration messages and returns the argument' do
        expect(suite_class.configuration_messages(messages)).to eq(messages)
        expect(suite_class.instance_variable_get(:@configuration_messages)).to eq(messages)
      end
    end

    context 'when no check_configuration_block is present' do
      it 'returns an empty array' do
        expect(suite_class.configuration_messages).to eq([])
      end
    end

    context 'when check_configuration_block is present' do
      it 'calls the block if configuration_messages is falsy' do
        suite_class.check_configuration { messages }

        expect(suite_class.configuration_messages).to eq(messages)
      end

      it 'returns the existing configuration_messages if they are truthy' do
        block = proc { messages }
        allow(block).to receive(:call).and_return(messages)
        suite_class.configuration_messages([])
        suite_class.check_configuration(&block)

        expect(suite_class.configuration_messages).to eq([])
        expect(block).to_not have_received(:call)
      end
    end

    context 'when force_recheck is true' do
      context 'when no check_configuration_block is present' do
        it 'returns an empty array' do
          expect(suite_class.configuration_messages(force_recheck: true)).to eq([])
        end

        it 'calls the existing configuration block even if messages are already present' do
          block = proc { [] }
          allow(block).to receive(:call).and_return([])
          suite_class.configuration_messages(messages)
          suite_class.check_configuration(&block)

          expect(suite_class.configuration_messages(force_recheck: true)).to eq([])
          expect(block).to have_received(:call)
        end
      end
    end
  end
end
