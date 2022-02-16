RSpec.describe Inferno::Web::Serializers::TestSuite do
  let(:suite) { InfrastructureTest::Suite }
  let(:summary_keys) do
    [
      'id',
      'title',
      'short_title',
      'description',
      'short_description',
      'input_instructions',
      'test_count',
      'version'
    ]
  end
  let(:full_keys) do
    summary_keys + ['configuration_messages', 'test_groups']
  end

  it 'serializes a suite summary view' do
    serialized_suite = JSON.parse(described_class.render(suite, view: :summary))

    expect(serialized_suite.keys).to match_array(summary_keys)
    expect(serialized_suite['id']).to eq(suite.id.to_s)
    expect(serialized_suite['title']).to eq(suite.title)
    expect(serialized_suite['short_title']).to eq(suite.short_title)
    expect(serialized_suite['description']).to eq(suite.description)
    expect(serialized_suite['short_description']).to eq(suite.short_description)
    expect(serialized_suite['input_instructions']).to eq(suite.input_instructions)
    expect(serialized_suite['test_count']).to eq(suite.test_count)
    expect(serialized_suite['version']).to eq(suite.version)
  end

  it 'serializes a full suite view' do
    serialized_suite = JSON.parse(described_class.render(suite, view: :full))
    expected_messages = [
      {
        'type' => 'error',
        'message' => 'This suite has a configuration error message'
      }
    ]

    expect(serialized_suite.keys).to match_array(full_keys)
    expect(serialized_suite['id']).to eq(suite.id.to_s)
    expect(serialized_suite['title']).to eq(suite.title)
    expect(serialized_suite['short_title']).to eq(suite.short_title)
    expect(serialized_suite['description']).to eq(suite.description)
    expect(serialized_suite['short_description']).to eq(suite.short_description)
    expect(serialized_suite['input_instructions']).to eq(suite.input_instructions)
    expect(serialized_suite['test_count']).to eq(suite.test_count)
    expect(serialized_suite['version']).to eq(suite.version)
    expect(serialized_suite['configuration_messages']).to eq(expected_messages)
    expect(serialized_suite['test_groups'].length).to eq(suite.groups.length)
  end
end
