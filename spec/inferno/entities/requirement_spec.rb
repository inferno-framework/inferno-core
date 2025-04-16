RSpec.describe Inferno::Entities::Requirement do
  describe '.expand_requirement_ids' do
    it 'returns an empty array of there are no sub_requirements' do
      expect(described_class.expand_requirement_ids(nil)).to eq([])
    end

    it 'returns full ids unchanged' do
      ids = ['criteria3@1', 'criteria4@2']

      expect(described_class.expand_requirement_ids(ids.join(','))).to eq(ids)
    end

    it 'expands id ranges' do
      ids = ['criteria3@1-3', 'criteria4@2']
      expected_ids = [
        'criteria3@1',
        'criteria3@2',
        'criteria3@3',
        'criteria4@2'
      ]

      expect(described_class.expand_requirement_ids(ids.join(','))).to eq(expected_ids)
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

      expect(described_class.expand_requirement_ids(ids.join(','))).to eq(expected_ids)
    end
  end
end
