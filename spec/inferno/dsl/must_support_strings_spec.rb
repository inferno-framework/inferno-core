require_relative '../../../lib/inferno/dsl/must_support_strings'

RSpec.describe Inferno::DSL::MustSupportStrings do
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
