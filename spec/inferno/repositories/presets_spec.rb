require_relative '../../../lib/inferno/repositories/presets'
require_relative '../../../lib/inferno/entities/preset'

RSpec.describe Inferno::Repositories::Presets do
  subject(:presets) { described_class.new }

  describe '#insert_from_file' do
    let(:simple_json) do
      File.realpath(File.join(Dir.pwd, 'spec/fixtures/simple_preset.json'))
    end

    let(:simple_erb) do
      File.realpath(File.join(Dir.pwd, 'spec/fixtures/simple_preset.json.erb'))
    end

    let(:uuid) { SecureRandom.uuid }

    before { allow(SecureRandom).to receive(:uuid).and_return(uuid) }

    context 'when given a JSON document' do
      let(:expected_preset) do
        Inferno::Entities::Preset.new(
          {
            id: uuid,
            test_suite_id: 'simple_json',
            type: 'text',
            title: 'Simple JSON Preset',
            inputs: [
              name: 'url',
              type: 'text',
              title: 'Title',
              description: 'Description',
              value: 'https://hardcoded.example.org'
            ]
          }
        )
      end

      it 'creates and inserts a preset' do
        inserted = presets.insert_from_file(simple_json)

        # to_json is a lazy way of comparing two instances' equality
        expect(inserted.to_json).to eq(expected_preset.to_json)
      end
    end

    context 'when given an ERB template and an ENV' do
      before do
        ENV['REFERENCE_SERVER_URL'] = 'http://example.com'
      end

      after do
        ENV.delete('REFERENCE_SERVER_URL')
      end

      it 'creates and inserts a preset' do
        inserted = presets.insert_from_file(simple_erb)

        expect(inserted.inputs.first[:value]).to eq('http://example.com')
      end
    end

    context 'when given an ERB template' do
      it 'creates and inserts a preset' do
        inserted = presets.insert_from_file(simple_erb)

        expect(inserted.inputs.first[:value]).to eq('http://default.example.com')
      end
    end
  end
end
