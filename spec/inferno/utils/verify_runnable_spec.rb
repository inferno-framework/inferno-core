require_relative '../../../lib/inferno/utils/verify_runnable'

RSpec.describe Inferno::Utils::VerifyRunnable do
  describe '#verify_runnable' do
    let(:dummy_class) { Class.new { include Inferno::Utils::VerifyRunnable } }
    let(:dummy) { dummy_class.new }
    let(:suite) { BasicTestSuite::Suite }
    let(:group) { BasicTestSuite::AbcGroup }
    let(:good_inputs) { [{name: 'input1', value: 'baz'}, {name: 'input2', value: 'foo'}] }
    let(:bad_inputs) { [{name: :input2, value: :foo}] }
    let(:unrunnable) { BasicTestSuite::DefGroup.tests.first }

    it 'is defined' do
      expect(described_class.method_defined?(:verify_runnable)).to eq(true)
    end

    it 'allows legit runnables' do
      expect { dummy.verify_runnable(suite, good_inputs, {}) }.not_to raise_error
    end

    it 'rejects bad inputs' do
      expect { dummy.verify_runnable(group, bad_inputs, {}) }.to raise_error(Inferno::Exceptions::RequiredInputsNotFound)
    end

    it 'rejects tests that are part of run_as_group' do
      expect { dummy.verify_runnable(unrunnable, [], {}) }.to raise_error(Inferno::Exceptions::NotUserRunnableException)
    end
  end
end
