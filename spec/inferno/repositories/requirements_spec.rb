RSpec.describe Inferno::Repositories::Requirements do
  subject(:requirements) { described_class.new }

  describe '#insert_from_file' do
    let(:csv) do
      File.realpath(File.join(Dir.pwd, 'spec/fixtures/simple_requirements.csv'))
    end
    let(:req_one) do
      Inferno::Entities::Requirement.new(
        {
          id: 'sample-criteria@1',
          requirement: 'requirement',
          conformance: 'SHALL',
          actor: 'Client',
          sub_requirements: ['sample-criteria@2'],
          conditionality: 'false'
        }
      )
    end
    let(:req2) do
      Inferno::Entities::Requirement.new(
        {
          id: 'sample-criteria@2',
          requirement: 'requirement',
          conformance: 'SHALL',
          actor: 'Client',
          sub_requirements: [],
          conditionality: 'false'
        }
      )
    end

    it 'creates and inserts all requirements from the csv file' do
      expect { requirements.insert_from_file(csv) }.to change { requirements.all.size }.by(2)
      expect(requirements.find(req_one.id).to_hash).to eq(req_one.to_hash)
      expect(requirements.find(req2.id).to_hash).to eq(req2.to_hash)
    end
  end
end
