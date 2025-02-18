require_relative '../../../../lib/inferno/apps/web/serializers/suite_option'

RSpec.describe Inferno::Web::Serializers::SuiteOption do
  let(:params) do
    {
      id: :id,
      default: 'VALUE1',
      description: 'DESCRIPTION',
      list_options: [
        { label: 'LABEL1', value: 'VALUE1' },
        { label: 'LABEL2', value: 'VALUE2' },
        { label: 'LABEL3', value: 'VALUE3' }
      ],
      value: 'VALUE3'
    }
  end
  let(:suite_option) { Inferno::DSL::SuiteOption.new(params) }

  it 'includes all fields' do
    serialized_result = JSON.parse(described_class.render(suite_option))

    expected_result = JSON.parse(params.to_json)

    expect(serialized_result).to eq(expected_result)
  end
end
