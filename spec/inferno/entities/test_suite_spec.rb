RSpec.describe Inferno::Entities::TestSuite do
  let!(:suite_class) { Class.new(described_class) }

  describe '.group' do
    let!(:group_class) { Class.new(Inferno::Entities::TestGroup) }
    let(:title) { 'GROUP_TITLE' }
    let(:id) { 'GROUP_ID' }

    before do
      suite_class.id(SecureRandom.uuid)
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
          title:,
          id:
        }

        suite_class.group metadata

        expect(suite_class.groups.length).to eq(1)

        expect(suite_class.groups.first.title).to eq(title)
        expect(suite_class.groups.first.id).to eq("#{suite_class.id}-#{id}")
      end
    end

    context 'with string and hash arguments' do
      it 'adds a group with a title from the string and other metadata from the hash' do
        metadata = { id: }

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

  describe '.links' do
    let(:links) do
      [
        { type: 'custom_type', label: 'One', url: 'http://one.com' }
      ]
    end

    specify 'it returns an empty array if no links are set' do
      expect(suite_class.links).to eq([])
    end

    specify 'it can set and retrieve a list of http links for display' do
      suite_class.links links
      link = suite_class.links.first
      expect(link[:label]).to eq('One')
      expect(link[:url]).to eq('http://one.com')
      expect(link[:type]).to eq('custom_type')
    end
  end

  describe '.add_link' do
    specify 'it adds a custom link to the list' do
      suite_class.add_link('custom_type', 'One', 'http://one.com')
      link = suite_class.links.first
      expect(link[:type]).to eq('custom_type')
      expect(link[:label]).to eq('One')
      expect(link[:url]).to eq('http://one.com')
    end
  end

  describe '.source_code_url' do
    specify 'it adds a source code link to the list' do
      suite_class.source_code_url('http://github.com/source_code')
      link = suite_class.links.first
      expect(link[:type]).to eq('source_code')
      expect(link[:label]).to eq('Open Source')
      expect(link[:url]).to eq('http://github.com/source_code')
    end

    specify 'it allows overriding the label for source code links' do
      suite_class.source_code_url('http://github.com/source_code', label: 'My Source')
      link = suite_class.links.first
      expect(link[:label]).to eq('My Source')
    end
  end

  describe '.ig_url' do
    specify 'it adds an implementation guide link to the list' do
      suite_class.ig_url('http://ig.example.com')
      link = suite_class.links.first
      expect(link[:type]).to eq('ig')
      expect(link[:label]).to eq('Implementation Guide')
      expect(link[:url]).to eq('http://ig.example.com')
    end

    specify 'it allows overriding the label for IG links' do
      suite_class.ig_url('http://ig.example.com', label: 'My IG')
      link = suite_class.links.first
      expect(link[:label]).to eq('My IG')
    end
  end

  describe '.download_url' do
    specify 'it adds a download link to the list' do
      suite_class.download_url('http://example.com/download')
      link = suite_class.links.first
      expect(link[:type]).to eq('download')
      expect(link[:label]).to eq('Download')
      expect(link[:url]).to eq('http://example.com/download')
    end

    specify 'it allows overriding the label for download links' do
      suite_class.download_url('http://example.com/download', label: 'Get Latest Version')
      link = suite_class.links.first
      expect(link[:label]).to eq('Get Latest Version')
    end
  end

  describe '.report_issue_url' do
    specify 'it adds a report issue link to the list' do
      suite_class.report_issue_url('http://example.com/report')
      link = suite_class.links.first
      expect(link[:type]).to eq('report_issue')
      expect(link[:label]).to eq('Report Issue')
      expect(link[:url]).to eq('http://example.com/report')
    end

    specify 'it allows overriding the label for report issue links' do
      suite_class.report_issue_url('http://example.com/report', label: 'Report Problem')
      link = suite_class.links.first
      expect(link[:label]).to eq('Report Problem')
    end
  end
end
