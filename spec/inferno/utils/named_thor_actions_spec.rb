require_relative '../../../lib/inferno/utils/named_thor_actions'

RSpec.describe Inferno::Utils::NamedThorActions do
  let(:dummy_class) do
    Class.new do
      include Inferno::Utils::NamedThorActions
      attr_accessor :name
    end
  end

  %w[test_fhir_app test-fhir-app TestFhirApp testFhir_app].each do |name|
    context "given name #{name}" do
      let(:dummy) do
        dummy_instance = dummy_class.new
        dummy_instance.name = name
        dummy_instance
      end

      it 'returns root name in kebab case' do
        expect(dummy.root_name).to eq('test-fhir-app')
      end

      it 'returns library name in snake case' do
        expect(dummy.library_name).to eq('test_fhir_app')
      end

      it 'returns module name in pascal case' do
        expect(dummy.module_name).to eq('TestFhirApp')
      end

      it 'returns human name in sentence case' do
        expect(dummy.human_name).to eq('Test fhir app')
      end

      it 'returns title name in title case' do
        expect(dummy.title_name).to eq('Test Fhir App')
      end

      it 'returns proper test suite id' do
        expect(dummy.test_suite_id).to eq('test_fhir_app_test_suite')
      end
    end
  end
end
