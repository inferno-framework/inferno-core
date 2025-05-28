require_relative '../../../../lib/inferno/apps/web/serializers/test_suite'
require 'active_support/core_ext/hash/indifferent_access'

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
      'version',
      'presets',
      'suite_options',
      'links',
      'suite_summary'
    ]
  end
  let(:full_keys) do
    summary_keys + ['configuration_messages', 'test_groups', 'inputs', 'verifies_requirements']
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
    expect(serialized_suite['presets']).to eq([])
    expect(serialized_suite['suite_summary']).to eq(suite.suite_summary)
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
    expect(serialized_suite['presets']).to eq([])
    expect(serialized_suite['suite_summary']).to eq(suite.suite_summary)
    expect(serialized_suite['verifies_requirements']).to eq(suite.verifies_requirements)

    expected_links = suite.links.map(&:with_indifferent_access)
    expect(serialized_suite['links']).to eq(expected_links)
  end

  it 'includes preset summaries' do
    demo_suite = DemoIG_STU1::DemoSuite
    serialized_suite = JSON.parse(described_class.render(demo_suite, view: :summary))
    expect(serialized_suite['presets']).to be_an(Array)
    expect(serialized_suite['presets']).to be_present
    expect(serialized_suite['presets'].length).to eq(demo_suite.presets.length)
    expect(serialized_suite['presets']).to all(have_key('id'))
    expect(serialized_suite['presets']).to all(have_key('title'))
  end

  it 'serializes using selected options to filter groups' do
    options_suite = OptionsSuite::Suite
    options = [Inferno::DSL::SuiteOption.new(id: :ig_version, value: '1')]
    serialized_suite = JSON.parse(described_class.render(options_suite,
                                                         view: :full,
                                                         suite_options: options))

    expected_groups = options_suite.groups(options).map(&:id)
    received_groups = serialized_suite['test_groups'].collect { |group| group['id'] }

    expect(received_groups).to eq(expected_groups)
    expect(serialized_suite['test_count']).to eq(3)
    expect(serialized_suite['requirement_sets'].length).to eq(2)
  end

  it 'serializes using selected options to filter requirement_sets' do
    options_suite = OptionsSuite::Suite
    options = [Inferno::DSL::SuiteOption.new(id: :ig_version, value: '1')]
    serialized_suite = JSON.parse(described_class.render(options_suite,
                                                         view: :full,
                                                         suite_options: options))

    expect(serialized_suite['requirement_sets'].length).to eq(2)
  end

  context 'when requirments feature flag is not set' do
    it 'does not include requirements fields' do
      allow(Inferno::Feature).to receive(:requirements_enabled?).and_return(false)

      serialized_suite = JSON.parse(described_class.render(suite, view: :full))

      expect(serialized_suite).to include('id')
      expect(serialized_suite).to_not include('verifies_requirements')
    end
  end
end
