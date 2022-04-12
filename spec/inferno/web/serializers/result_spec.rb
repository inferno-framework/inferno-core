RSpec.describe Inferno::Web::Serializers::Result do
  let(:result) do
    repo_create(:result,
                input_json: JSON.generate([{ name: 'input', value: 'VALUE', type: 'some_type' }]),
                output_json: JSON.generate([{ name: 'output', value: 'VALUE', type: 'some_other_type' }]))
  end

  it 'includes input types' do
    serialized_result = JSON.parse(described_class.render(result))

    expect(serialized_result['inputs'].first['type']).to eq('some_type')
  end

  it 'includes output types' do
    serialized_result = JSON.parse(described_class.render(result))

    expect(serialized_result['outputs'].first['type']).to eq('some_other_type')
  end

  context 'when the runnable can not be found' do
    before { allow(result).to receive(:runnable).and_return(nil) }

    it 'does not raise an error' do
      expect { described_class.render(result) }.to_not raise_error
    end
  end
end
