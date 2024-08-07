require_relative '../../../lib/inferno/utils/persist_inputs'

RSpec.describe Inferno::Utils::PersistInputs do
  
  describe '#persist_inputs' do
    it 'is defined' do
      expect(described_class.method_defined?(:persist_inputs)).to eq(true)
    end
  end

end

