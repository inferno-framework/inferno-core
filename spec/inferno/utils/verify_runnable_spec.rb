require_relative '../../../lib/inferno/utils/verify_runnable.rb'

RSpec.describe Inferno::Utils::VerifyRunnable do
  describe '#verify_runnable' do
    it 'is defined' do
      expect(described_class.method_defined?(:verify_runnable)).to eq(true)
    end
  end
end
