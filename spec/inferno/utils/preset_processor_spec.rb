require_relative '../../../lib/inferno/utils/preset_processor'

RSpec.describe Inferno::Utils::PresetProcessor do
  let(:suite) { Inferno::DemoIG_STU1::DemoSuite }
  let(:session) { repo_create(:test_session, test_suite_id: 'options') }

  describe '#processed_inputs' do
    let(:base_preset_path) do
      File.realpath(File.join(Dir.pwd, 'spec/fixtures/options_preset.json'))
    end

    let(:base_preset) do
      Inferno::Repositories::Presets.new.insert_from_file(base_preset_path)
    end

    context 'with no options' do
      it 'handles preset inputs with no options' do
        processed_inputs = described_class.new(base_preset, session).processed_inputs

        expect(processed_inputs.length).to eq(base_preset.inputs.length)
        expect(processed_inputs.first[:value]).to eq(base_preset.inputs.first[:value])
      end
    end

    context 'with options' do
      let(:preset_with_options) do
        base_preset.tap do |preset|
          preset.inputs.first[:value_for_options] = [
            {
              options: [
                {
                  name: 'ig_version',
                  value: '2'
                },
                {
                  name: 'other_option',
                  value: '3'
                }
              ],
              value: 'OPTION_VALUE_1'
            },
            {
              options: [
                {
                  name: 'ig_version',
                  value: '1'
                },
                {
                  name: 'other_option',
                  value: '2'
                }
              ],
              value: 'OPTION_VALUE_2'
            }
          ]
        end
      end

      it 'uses the value that matches the selected options' do
        session.suite_options = [
          Inferno::DSL::SuiteOption.new(id: :ig_version, value: '1'),
          Inferno::DSL::SuiteOption.new(id: :other_option, value: '2')
        ]

        processed_inputs = described_class.new(preset_with_options, session).processed_inputs

        expect(processed_inputs.first[:value]).to eq('OPTION_VALUE_2')
      end

      it 'uses the plain value if the options do not match' do
        session.suite_options = [
          Inferno::DSL::SuiteOption.new(id: :ig_version, value: '2'),
          Inferno::DSL::SuiteOption.new(id: :other_option, value: '2')
        ]

        processed_inputs = described_class.new(preset_with_options, session).processed_inputs

        expect(processed_inputs.first[:value]).to eq(preset_with_options.inputs.first[:value])
      end
    end
  end
end
