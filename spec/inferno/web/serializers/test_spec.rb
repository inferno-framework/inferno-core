RSpec.describe Inferno::Web::Serializers::Test do
  let(:test) { InfrastructureTest::SerializerTest }

  it 'serializes a test' do
    serialized_test = JSON.parse(described_class.render(test))

    expected_keys = ['id', 'short_id', 'description', 'inputs', 'outputs', 'title',
                     'user_runnable', 'optional', 'short_description', 'short_title',
                     'input_instructions']

    expect(serialized_test.keys).to match_array(expected_keys)
    expect(serialized_test['id']).to eq(test.id.to_s)
    expect(serialized_test['short_id']).to eq(test.short_id)
    expect(serialized_test['title']).to eq(test.title)
    expect(serialized_test['short_title']).to eq(test.short_title)
    expect(serialized_test['description']).to eq(test.description)
    expect(serialized_test['short_description']).to eq(test.short_description)
    expect(serialized_test['input_instructions']).to eq(test.input_instructions)
    expect(serialized_test['inputs'].length).to eq(test.inputs.length)
    expect(serialized_test['outputs'].length).to eq(test.outputs.length)

    test.available_inputs.each do |_identifier, definition|
      raw_input = serialized_test['inputs'].find { |serialized_input| serialized_input['name'] == definition.name }
      expect(raw_input).to be_present
      input = Inferno::Entities::Input.new(raw_input.symbolize_keys)

      expect(input).to eq(definition)
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
