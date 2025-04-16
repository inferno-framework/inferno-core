RSpec.describe Inferno::DSL::RequirementSet do
  describe '#expand_requirement_ids' do
    it 'returns an empty array if the requirements are blank' do
      expect(described_class.new({}).expand_requirement_ids).to eq([])
    end

    it 'returns full ids unchanged' do
      ids = ['criteria3@1', 'criteria4@2']

      expect(described_class.new(requirements: ids.join(',')).expand_requirement_ids).to eq(ids)
    end

    it 'expands id ranges' do
      ids = ['criteria3@1-3', 'criteria4@2']
      expected_ids = [
        'criteria3@1',
        'criteria3@2',
        'criteria3@3',
        'criteria4@2'
      ]

      expect(described_class.new(requirements: ids.join(',')).expand_requirement_ids).to eq(expected_ids)
    end

    it 'adds the requirement set when missing' do
      ids = ['criteria3@1', '2', '3', 'criteria4@2', '3']
      expected_ids = [
        'criteria3@1',
        'criteria3@2',
        'criteria3@3',
        'criteria4@2',
        'criteria4@3'
      ]

      expect(described_class.new(requirements: ids.join(',')).expand_requirement_ids).to eq(expected_ids)
    end
  end
end
