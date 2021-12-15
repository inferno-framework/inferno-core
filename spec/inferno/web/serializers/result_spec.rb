RSpec.describe Inferno::Web::Serializers::Result do
  let(:result) do
    Inferno::Entities::Result.new(
      output_json: JSON.generate([{ name: 'output', value: 'VALUE', type: 'some_type' }])
    )
  end

  it 'includes output types' do
    serialized_result = JSON.parse(described_class.render(result))

    expect(serialized_result['outputs'].first['type']).to eq('some_type')
  end
end
