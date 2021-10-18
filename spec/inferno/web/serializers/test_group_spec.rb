RSpec.describe Inferno::Web::Serializers::TestGroup do
  let(:group) { InfrastructureTest::SerializerGroup }
  let(:test) { group.tests.first }

  it 'serializes a group' do
    serialized_group = JSON.parse(described_class.render(group))

    expected_keys = ['id', 'description', 'inputs', 'outputs', 'title', 'test_count', 'test_groups', 'tests',
                     'run_as_group', 'user_runnable']

    expect(serialized_group.keys).to match_array(expected_keys)
    expect(serialized_group['id']).to eq(group.id.to_s)
    expect(serialized_group['title']).to eq(group.title)
    expect(serialized_group['description']).to eq(group.description)
    expect(serialized_group['inputs'].length).to eq(group.inputs.length)
    expect(serialized_group['outputs'].length).to eq(group.outputs.length)
    expect(serialized_group['test_count']).to eq(group.tests.length)
    expect(serialized_group['test_groups']).to be_empty
    expect(serialized_group['tests'].length).to eq(group.tests.length)

    group.input_definitions.each do |_identifier, definition|
      input = serialized_group['inputs'].find { |serialized_input| serialized_input['name'] == definition[:name].to_s }
      expect(input).to be_present
      definition.each do |key, value|
        expect(input[key.to_s]).to eq(value.to_s)
      end
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
