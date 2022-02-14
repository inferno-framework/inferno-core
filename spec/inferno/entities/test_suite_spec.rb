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
    let!(:example_test_suite_class) { Class.new(described_class) }

    let(:test_suite) do
      example_test_suite_class.version 'VERSION'
      example_test_suite_class
    end

    specify 'it gets/sets the version' do
      expect(test_suite.version).to eq('VERSION')
    end
  end
end
