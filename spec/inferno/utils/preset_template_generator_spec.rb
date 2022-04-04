RSpec.describe Inferno::Utils::PresetTemplateGenerator do
  let(:suite) { DemoIG_STU1::DemoSuite }
  let(:expected_template) do
    { title: 'Preset for Demonstration Suite',
      id: nil,
      test_suite_id: 'demo',
      inputs: [
        {
          name: 'url',
          type: 'text',
          title: 'URL',
          description: 'Insert url of FHIR server',
          value: 'https://inferno.healthit.gov/reference-server/r4'
        },
        { name: 'patient_id', type: 'text', title: 'Patient ID', value: '85' },
        { name: 'bearer_token', type: 'text', optional: true, value: 'SAMPLE_TOKEN' },
        { name: 'textarea', type: 'textarea', title: 'Textarea Input Example',
          description: 'Insert something like a patient resource json here', optional: true, value: nil },
        { name: 'radio',
          type: 'radio',
          title: 'Radio Group Input Example',
          optional: false,
          options: { list_options: [{ label: 'Label 1', value: 'value1' },
                                    { label: 'Label 2', value: 'value2' }] },
          value: nil },
        { name: 'patient_name', type: 'text', title: 'Patient Name',
          description: 'Example of locked, empty input field', locked: true, optional: true, value: nil },
        { name: 'url_locked', type: 'text', title: 'URL', description: 'Example of locked, filled input field',
          locked: true, value: 'https://inferno.healthit.gov/reference-server/r4' },
        { name: 'textarea_locked', type: 'textarea', title: 'Textarea Input',
          description: 'Example of locked, filled input field', locked: true, value: 'Hello Inferno demo user.' },
        { name: 'cancel_pause_time', type: 'text', value: '30' },
        { name: 'url1', type: 'text', value: nil }
      ] }
  end

  describe '#generate' do
    it 'generates the expected template' do
      generator = described_class.new(suite)
      template = generator.generate

      expect(template).to eq(expected_template)
    end
  end
end
