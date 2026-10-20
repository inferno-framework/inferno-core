require_relative '../../../lib/inferno/dsl/must_support_strings'

RSpec.describe Inferno::DSL::MustSupportStrings do
  describe '.element_string' do
    it 'includes a fixed value of false' do
      expect(described_class.element_string({ path: 'active', fixed_value: false })).to eq('active = false')
    end
  end

  describe '.slice_string' do
    it 'raises when the slice has no slice_id' do
      expect { described_class.slice_string({ path: 'category', slice_name: 'us-core' }) }
        .to raise_error(ArgumentError, /missing :slice_id/)
    end
  end

  describe '.extension_string' do
    it 'raises when the extension has no id' do
      expect { described_class.extension_string({ path: 'extension', slice_name: 'race' }) }
        .to raise_error(ArgumentError, /missing :id/)
    end
  end

  describe '.without_resource_type' do
    it 'removes a leading resource type' do
      expect(described_class.without_resource_type('Observation.component:FlowRate')).to eq('component:FlowRate')
    end

    it 'leaves an id without a resource type unchanged' do
      expect(described_class.without_resource_type('component:FlowRate')).to eq('component:FlowRate')
    end

    it 'returns nil when given nil' do
      expect(described_class.without_resource_type(nil)).to be_nil
    end
  end
end
