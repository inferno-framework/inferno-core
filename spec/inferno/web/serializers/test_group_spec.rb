require_relative '../../../../lib/inferno/apps/web/serializers/test_group'
require_relative '../../../../lib/inferno/utils/markdown_formatter'

RSpec.describe Inferno::Web::Serializers::TestGroup do
  include Inferno::Utils::MarkdownFormatter
  let(:group) { InfrastructureTest::SerializerGroup }

  before do
    options_multi_group = Class.new(OptionsSuite::AllVersionsGroup) do
      id SecureRandom.uuid
      group from: :v1_group,
            required_suite_options: { ig_version: '1' }

      group from: :v2_group,
            required_suite_options: { ig_version: '2' }
    end

    stub_const('OptionsMultiGroup', options_multi_group)
  end

  it 'serializes a group' do
    serialized_group = JSON.parse(described_class.render(group))

    expected_keys = ['id', 'short_id', 'description', 'inputs', 'outputs',
                     'title', 'test_count', 'test_groups', 'tests',
                     'run_as_group', 'user_runnable', 'optional', 'short_title',
                     'short_description', 'input_instructions',
                     'verifies_requirements']

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
    expect(serialized_group['verifies_requirements'].length).to eq(group.verifies_requirements.length)

    group.available_inputs.each_value do |definition|
      raw_input = serialized_group['inputs']
        .find { |serialized_input| serialized_input['name'] == definition.name }
        .symbolize_keys

      expect(raw_input).to be_present

      input = Inferno::Entities::Input.new(**raw_input)

      expect(input.name).to eq(definition.name)
      expect(input.type).to eq(definition.type)
      expect(input.default).to eq(definition.default)
      expect(input.description).to eq(format_markdown(definition.description))
    end

    group.output_definitions.each_value do |definition|
      output =
        serialized_group['outputs']
          .find { |serialized_output| serialized_output['name'] == definition[:name].to_s }
      expect(output).to be_present
      definition.each do |key, value|
        expect(output[key.to_s]).to eq(value.to_s)
      end
    end
  end

  it 'serializes using selected options to filter groups and tests' do
    options = [Inferno::DSL::SuiteOption.new(id: :ig_version, value: '2')]
    serialized_group = JSON.parse(described_class.render(OptionsMultiGroup,
                                                         suite_options: options))

    expected_tests = OptionsMultiGroup.tests(options).map(&:id)
    expected_groups = OptionsMultiGroup.groups(options).map(&:id)
    received_tests = serialized_group['tests'].collect { |test| test['id'] }
    recieved_groups = serialized_group['test_groups'].collect { |group| group['id'] }

    expect(received_tests).to eq(expected_tests)
    expect(recieved_groups).to eq(expected_groups)
    expect(serialized_group['test_count']).to eq(4)
  end
end
