RSpec.describe Inferno::Web::Serializers::Test do
  let(:test) { InfrastructureTest::SerializerTest }

  it 'serializes a test' do
    serialized_test = JSON.parse(described_class.render(test))

    expected_keys = ['id', 'description', 'inputs', 'outputs', 'title', 'user_runnable']

    expect(serialized_test.keys).to match_array(expected_keys)
    expect(serialized_test['id']).to eq(test.id.to_s)
    expect(serialized_test['title']).to eq(test.title)
    expect(serialized_test['description']).to eq(test.description)
    expect(serialized_test['inputs'].length).to eq(test.inputs.length)
    expect(serialized_test['outputs'].length).to eq(test.outputs.length)

    test.input_definitions.each do |_identifier, definition|
      input = serialized_test['inputs'].find { |serialized_input| serialized_input['name'] == definition[:name].to_s }
      expect(input).to be_present
      definition.each do |key, value|
        expect(input[key.to_s]).to eq(value.to_s)
      end
    end

    test.output_definitions.each do |_identifier, definition|
      output =
        serialized_test['outputs']
          .find { |serialized_output| serialized_output['name'] == definition[:name].to_s }
      expect(output).to be_present
      definition.each do |key, value|
        expect(output[key.to_s]).to eq(value.to_s)
      end
    end
  end
end
