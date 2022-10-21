RSpec.describe Inferno::Entities::TestGroup do
  describe '.group' do
    let!(:subgroup_class) { Class.new(described_class) }
    let!(:group_class) { Class.new(described_class) }
    let(:title) { 'GROUP_TITLE' }
    let(:id) { 'GROUP_ID' }

    before do
      allow(Class).to receive(:new).with(described_class).and_return(subgroup_class)
    end

    context 'without arguments' do
      it 'adds an empty group to the group' do
        group_class.group

        expect(group_class.groups.length).to eq(1)
        expect(group_class.groups.first).to eq(subgroup_class)
      end
    end

    context 'with a string argument' do
      it 'adds a group with the given title to the group' do
        group_class.group title

        expect(group_class.groups.length).to eq(1)
        expect(group_class.groups.first.title).to eq(title)
      end
    end

    context 'with a hash argument' do
      it 'adds a group with the metadata defined in the hash' do
        metadata = {
          title:,
          id:
        }

        group_class.group metadata

        expect(group_class.groups.length).to eq(1)

        expect(group_class.groups.first.title).to eq(title)
        expect(group_class.groups.first.id).to eq("#{group_class.id}-#{id}")
      end
    end

    context 'with string and hash arguments' do
      it 'adds a group with a title from the string and other metadata from the hash' do
        metadata = { id: }

        group_class.group title, metadata

        expect(group_class.groups.length).to eq(1)
        expect(group_class.groups.first.title).to eq(title)

        expect(group_class.groups.first.id).to eq("#{group_class.id}-#{id}")
      end
    end

    context 'with a block argument' do
      it 'adds a group which evaluates that block' do
        group_class.group do
          title 'TITLE'
          id 'ID'
        end

        expect(group_class.groups.length).to eq(1)
        expect(group_class.groups.first.title).to eq('TITLE')
        expect(group_class.groups.first.id).to eq("#{group_class.id}-ID")
      end
    end
  end

  describe '.test' do
    let!(:test_class) { Class.new(Inferno::Entities::Test) }
    let!(:group_class) { Class.new(described_class) }
    let(:title) { 'TEST_TITLE' }
    let(:id) { 'TEST_ID' }

    before do
      allow(Class).to receive(:new).with(Inferno::Entities::Test).and_return(test_class)
    end

    context 'without arguments' do
      it 'adds an empty test to the group' do
        group_class.test

        expect(group_class.tests.length).to eq(1)
        expect(group_class.tests.first).to eq(test_class)
      end
    end

    context 'with a string argument' do
      it 'adds a test with the given title to the group' do
        group_class.test title

        expect(group_class.tests.length).to eq(1)
        expect(group_class.tests.first.title).to eq(title)
      end
    end

    context 'with a hash argument' do
      it 'adds a test with the metadata defined in the hash' do
        metadata = {
          title:,
          id:
        }

        group_class.test metadata

        expect(group_class.tests.length).to eq(1)

        expect(group_class.tests.first.title).to eq(title)
        expect(group_class.tests.first.id).to eq("#{group_class.id}-#{id}")
      end
    end

    context 'with string and hash arguments' do
      it 'adds a test with a title from the string and other metadata from the hash' do
        metadata = { id: }

        group_class.test title, metadata

        expect(group_class.tests.length).to eq(1)
        expect(group_class.tests.first.title).to eq(title)

        expect(group_class.tests.first.id).to eq("#{group_class.id}-#{id}")
      end
    end

    context 'with a block argument' do
      it 'adds a test which that block' do
        block = proc { assert 1 == 2 }
        group_class.test('TITLE') { run(&block) }

        expect(group_class.tests.length).to eq(1)
        expect(group_class.tests.first.title).to eq('TITLE')
        expect(group_class.tests.first.block).to eq(block)
      end
    end
  end
end
