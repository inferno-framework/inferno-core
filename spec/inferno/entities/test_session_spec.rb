RSpec.describe Inferno::Entities::TestSession do
  describe '#suite_options' do
    let(:suite) { OptionsSuite::Suite }

    context 'when no options have been selected' do
      let(:session) { described_class.new(test_suite_id: suite.id) }

      it 'assigns the first possible value as default for each option' do
        selected_options = session.suite_options

        expect(selected_options.length).to eq(suite.suite_options.length)

        selected_option = selected_options.first
        available_option = suite.suite_options.first

        expect(selected_option.id).to eq(available_option.id)
        expect(selected_option.value).to eq(available_option.list_options.first[:value])
      end
    end

    context 'when options have been selected' do
      let(:session) do
        described_class.new(
          test_suite_id: suite.id,
          suite_options: [Inferno::DSL::SuiteOption.new(id: :ig_version, value: '2')]
        )
      end

      it 'does not overwrite selected options' do
        selected_options = session.suite_options

        expect(selected_options.length).to eq(suite.suite_options.length)

        selected_option = selected_options.first
        available_option = suite.suite_options.first

        expect(selected_option.id).to eq(available_option.id)
        expect(selected_option.value).to eq('2')
      end
    end
  end
end
