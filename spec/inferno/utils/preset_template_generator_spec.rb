require_relative '../../../lib/inferno/utils/preset_template_generator'

RSpec.describe Inferno::Utils::PresetTemplateGenerator do
  let(:suite) { DemoIG_STU1::DemoSuite }
  let(:expected_template) do
    { title: 'Preset for Demonstration Suite',
      id: nil,
      test_suite_id: 'demo',
      inputs: [
        {
          name: 'url',
          _type: 'text',
          _title: 'URL',
          _description: 'Insert url of FHIR server',
          value: 'https://inferno.healthit.gov/reference-server/r4'
        },
        { name: 'patient_id', _type: 'text', _title: 'Patient ID',
          _description: %(
            ### This is a markdown description.
            This is a new line.
          ), value: '85' },
        { name: 'bearer_token', _type: 'text', _optional: true, value: 'SAMPLE_TOKEN' },
        { name: 'textarea', _type: 'textarea', _title: 'Textarea Input Example',
          _description: 'Insert something like a patient resource json here', _optional: true, value: nil },
        { name: 'radio',
          _type: 'radio',
          _title: 'Radio Group Input Example',
          _description: 'Radio description',
          _optional: false,
          _options: { list_options: [{ label: 'Label 1', value: 'value1' },
                                     { label: 'Label 2', value: 'value2' }] },
          value: nil },
        { name: 'checkbox_group',
          _type: 'checkbox',
          _title: 'Checkbox Group Input Example',
          _description: 'Checkbox description',
          _optional: false,
          _options: { list_options: [{ label: 'Label 1', value: 'value1' },
                                     { label: 'Label 2', value: 'value2' }] },
          value: ['value2'] },
        { name: 'locked_checkbox_group',
          _type: 'checkbox',
          _title: 'Locked Checkbox Group Input Example',
          _description: 'Checkbox description',
          _optional: false,
          _locked: true,
          _options: { list_options: [{ label: 'Label 1', value: 'value1' },
                                     { label: 'Label 2', locked: true, value: 'value2' }] },
          value: ['value2'] },
        { name: 'locked_single_checkbox_group',
          _type: 'checkbox',
          _title: 'Locked Single Checkbox in Group Input Example',
          _description: 'Checkbox description',
          _optional: false,
          _options: { list_options: [{ label: 'Label 1', value: 'value1' },
                                     { label: 'Label 2', locked: true, value: 'value2' }] },
          value: ['value2'] },
        { name: 'single_checkbox',
          _type: 'checkbox',
          _title: 'Single Checkbox Input Example',
          _description: 'Checkbox description',
          _optional: false,
          value: ['true'] },
        { name: 'locked_single_checkbox',
          _type: 'checkbox',
          _title: 'Locked Single Checkbox Input Example',
          _description: 'Checkbox description',
          _optional: false,
          _locked: true,
          value: ['true'] },
        { name: 'credentials',
          _description: 'OAuth Credentials description',
          _optional: true,
          _title: 'OAuth Credentials Group Input Example',
          _type: 'oauth_credentials',
          value: nil },
        { name: 'patient_name', _type: 'text', _title: 'Patient Name',
          _description: 'Example of locked, empty input field', _locked: true, _optional: true, value: nil },
        { name: 'url_locked', _type: 'text', _title: 'URL', _description: 'Example of locked, filled input field',
          _locked: true, value: 'https://inferno.healthit.gov/reference-server/r4' },
        { name: 'textarea_locked', _type: 'textarea', _title: 'Textarea Input',
          _description: 'Example of locked, filled input field', _locked: true, value: 'Hello Inferno demo user.' },
        { name: 'locked_required_empty', _type: 'text', _title: 'Locked and Required (should not be runnable)',
          _description: 'Example of locked, empty, required field', _locked: true, value: nil },
        { name: 'locked_required_filled', _type: 'text', _title: 'Locked and Required (should be runnable)',
          _description: 'Example of locked, filled, required field', value: 'example text',
          _locked: true },
        { name: 'locked_optional_empty', _type: 'text', _title: 'Locked and Optional (should be runnable)',
          _description: 'Example of locked, empty, optional field', _locked: true, _optional: true,
          value: nil },
        { name: 'locked_optional_filled', _type: 'text', _title: 'Locked and Optional (should be runnable)',
          _description: 'Example of locked, filled, optional field', value: 'example text',
          _locked: true, _optional: true },
        { name: 'hidden_optional_empty', _type: 'text', _title: 'Hidden and Optional (should be runnable)',
          _description: 'Example of hidden, empty, optional field', _hidden: true, _optional: true, value: nil },
        { name: 'hidden_optional_filled', _type: 'text', _title: 'Hidden and Optional (should be runnable)',
          _description: 'Example of hidden, filled, optional field', value: 'example text',
          _hidden: true, _optional: true },
        { name: 'hidden_locked_filled', _type: 'text', _title: 'Hidden and Locked (should be runnable)',
          _description: 'Example of hidden, filled, locked field', value: 'example text',
          _hidden: true, _locked: true },
        { name: 'auth_info_credentials', _type: :auth_info, _title: 'AuthInfo Credentials',
          _description: 'Access mode AuthInfo input with `issue_time` and `expires_in` fields hidden',
          value: {
            client_id: 'SAMPLE_PUBLIC_CLIENT_ID',
            requested_scopes: 'launch/patient openid fhirUser patient/*.*',
            pkce_support: 'enabled',
            pkce_code_challenge_method: 'S256',
            auth_request_method: 'GET',
            access_token: 'SAMPLE_TOKEN',
            refresh_token: 'SAMPLE_REFRESH_TOKEN',
            expires_in: '3600',
            issue_time: '2025-03-13T14:15:50-04:00'
          }.to_json,
          _options: {
            mode: 'access',
            components: [
              {
                name: :issue_time,
                optional: true,
                hidden: true
              },
              {
                name: :expires_in,
                optional: true,
                hidden: true
              }
            ]
          } },
        { name: 'auth_mode_credentials', _type: :auth_info, _title: 'Auth Mode AuthInfo Credentials',
          _description: 'Auth mode AuthInfo input with `pkce_support` field hidden',
          value: AuthInfoConstants.public_default.to_json,
          _options: {
            mode: 'auth',
            components: [
              { name: :pkce_support, locked: true, hidden: true }
            ]
          } },
        { name: 'cancel_pause_time', _type: 'text', value: '30' },
        { name: 'url1', _type: 'text', value: nil },
        { name: 'custom_bearer_token', _type: 'text',
          _description: 'This bearer token will be used to identify the incoming request', value: nil },
        { name: 'get_type_radio', _type: 'radio', _title: 'How to get Bundle (Radio)',
          _options: { list_options: [
            { value: 'copy_paste', label: 'Paste JSON' },
            { value: 'url', label: 'URL to FHIR Bundle' },
            { value: 'summary_op', label: '$summary Operation' }
          ] }, value: nil },
        { name: 'bundle_copy_paste_radio', _type: 'textarea', _title: 'Paste JSON (Radio)',
          _optional: true, value: nil, _enable_when: { input_name: 'get_type_radio', value: 'copy_paste' } },
        { name: 'bundle_url_radio', _type: 'text', _title: 'URL to FHIR Bundle (Radio)',
          _optional: true, value: nil, _enable_when: { input_name: 'get_type_radio', value: 'url' } },
        { name: 'fhir_server_url_radio', _type: 'text', _title: 'FHIR Server URL (Radio)',
          _optional: true, value: nil, _enable_when: { input_name: 'get_type_radio', value: 'summary_op' } },
        { name: 'patient_identifier_radio', _type: 'text', _title: 'Patient ID (Radio)',
          _optional: true, value: nil, _enable_when: { input_name: 'get_type_radio', value: 'summary_op' } },
        { name: 'get_type_select', _type: 'select', _title: 'How to get Bundle (Select)',
          _options: { list_options: [
            { value: 'copy_paste', label: 'Paste JSON' },
            { value: 'url', label: 'URL to FHIR Bundle' },
            { value: 'summary_op', label: '$summary Operation' }
          ] }, value: 'copy_paste' },
        { name: 'bundle_copy_paste_select', _type: 'textarea', _title: 'Paste JSON (Select)',
          _optional: true, value: nil, _enable_when: { input_name: 'get_type_select', value: 'copy_paste' } },
        { name: 'bundle_url_select', _type: 'text', _title: 'URL to FHIR Bundle (Select)',
          _optional: true, value: nil, _enable_when: { input_name: 'get_type_select', value: 'url' } },
        { name: 'fhir_server_url_select', _type: 'text', _title: 'FHIR Server URL (Select)',
          _optional: true, value: nil, _enable_when: { input_name: 'get_type_select', value: 'summary_op' } },
        { name: 'patient_identifier_select', _type: 'text', _title: 'Patient ID (Select)',
          _optional: true, value: nil, _enable_when: { input_name: 'get_type_select', value: 'summary_op' } }
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
