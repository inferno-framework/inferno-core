require_relative '../../../../lib/inferno/apps/web/serializers/test'

RSpec.describe Inferno::Web::Serializers::Test do
  let(:test) { InfrastructureTest::SerializerTest }

  it 'serializes a test' do
    serialized_test = JSON.parse(described_class.render(test))

    expected_keys = ['id', 'short_id', 'description', 'inputs', 'outputs', 'title',
                     'user_runnable', 'optional', 'short_description', 'short_title',
                     'input_instructions', 'verifies_requirements']

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
    expect(serialized_test['verifies_requirements'].length).to eq(test.verifies_requirements.length)

    test.available_inputs.each_value do |definition|
      raw_input = serialized_test['inputs']
        .find { |serialized_input| serialized_input['name'] == definition.name }
        .symbolize_keys

      expect(raw_input).to be_present

      input = Inferno::Entities::Input.new(**raw_input)

      expect(input).to eq(definition)
    end

    test.output_definitions.each_value do |definition|
      output =
        serialized_test['outputs']
          .find { |serialized_output| serialized_output['name'] == definition[:name].to_s }
      expect(output).to be_present
      definition.each do |key, value|
        expect(output[key.to_s]).to eq(value.to_s)
      end
    end
  end

  context 'when part of a session' do
    let(:test) { RequirementsSuite::Suite.groups.last.tests.first }
    let(:session) { repo_create(:test_session, test_suite_id: RequirementsSuite::Suite.id) }
    let(:suite_requirement_ids) do
      Inferno::Repositories::Requirements.new
        .requirements_for_suite(session.test_suite_id, session.id)
        .map(&:id)
    end

    it 'excludes requirements which not in the suite requirement sets' do
      serialized_test = JSON.parse(described_class.render(test, suite_requirement_ids:))

      expect(serialized_test['verifies_requirements']).to eq(['sample-criteria-proposal@6'])
    end
  end
end
