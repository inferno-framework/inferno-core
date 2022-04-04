RSpec.describe Inferno::Web::Serializers::TestGroup do
  let(:group) { InfrastructureTest::SerializerGroup }
  let(:test) { group.tests.first }

  it 'serializes a group' do
    serialized_group = JSON.parse(described_class.render(group))

    expected_keys = ['id', 'short_id', 'description', 'inputs', 'outputs', 'title',
                     'test_count', 'test_groups', 'tests', 'run_as_group', 'user_runnable',
                     'optional', 'short_title', 'short_description', 'input_instructions']

    expect(serialized_group.keys).to match_array(expected_keys)
    expect(serialized_group['id']).to eq(group.id.to_s)
    expect(serialized_group['short_id']).to eq(group.short_id.to_s)
    expect(serialized_group['title']).to eq(group.title)
    expect(serialized_group['short_title']).to eq(group.short_title)
    expect(serialized_group['description']).to eq(group.description)
    expect(serialized_group['short_description']).to eq(group.short_description)
    expect(serialized_group['input_instructions']).to eq(group.input_instructions)
    expect(serialized_group['inputs'].length).to eq(group.available_inputs.length)
    expect(serialized_group['outputs'].length).to eq(group.outputs.length)
    expect(serialized_group['test_count']).to eq(group.tests.length)
    expect(serialized_group['test_groups']).to be_empty
    expect(serialized_group['tests'].length).to eq(group.tests.length)

    group.available_inputs.each do |_identifier, definition|
      raw_input = serialized_group['inputs'].find { |serialized_input| serialized_input['name'] == definition.name }
      expect(raw_input).to be_present
      input = Inferno::Entities::Input.new(raw_input.symbolize_keys)

      expect(input).to eq(definition)
    end

    group.output_definitions.each do |_identifier, definition|
      output =
        serialized_group['outputs']
          .find { |serialized_output| serialized_output['name'] == definition[:name].to_s }
      expect(output).to be_present
      definition.each do |key, value|
        expect(output[key.to_s]).to eq(value.to_s)
      end
    end
  end
end
