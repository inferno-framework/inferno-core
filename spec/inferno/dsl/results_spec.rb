RSpec.describe Inferno::DSL::Results, :runnable do
  let(:suite_id) { 'demo' }

  describe '#skip' do
    let(:message) { 'SKIP_MESSAGE' }
    let(:skip_test) { Inferno::Repositories::Tests.new.find('skip') }

    before(:context) { Inferno::Repositories::Tests.new.insert(Class.new(Inferno::Test) { id 'skip' }) }

    context 'when given a message' do
      it 'skips' do
        skip_test.run { skip 'SKIP_MESSAGE' }

        result = run(skip_test)

        expect(result.result).to eq('skip')
        expect(result.result_message).to eq(message)
      end
    end

    context 'when given a block' do
      it 'skips if an assertion fails in the block' do
        skip_test.run { skip { assert false, 'SKIP_MESSAGE' } }

        result = run(skip_test)

        expect(result.result).to eq('skip')
        expect(result.result_message).to eq(message)
      end

      it 'does not skip if an assertion does not fail in the block' do
        skip_test.run { skip { assert true, 'SKIP_MESSAGE' } }

        result = run(skip_test)

        expect(result.result).to eq('pass')
      end
    end
  end

  describe '#omit' do
    let(:message) { 'OMIT_MESSAGE' }
    let(:omit_test) { Inferno::Repositories::Tests.new.find('omit') }

    before(:context) { Inferno::Repositories::Tests.new.insert(Class.new(Inferno::Test) { id 'omit' }) }

    context 'when given a message' do
      it 'omits' do
        omit_test.run { omit 'OMIT_MESSAGE' }

        result = run(omit_test)

        expect(result.result).to eq('omit')
        expect(result.result_message).to eq(message)
      end
    end

    context 'when given a block' do
      it 'omits if an assertion fails in the block' do
        omit_test.run { omit { assert false, 'OMIT_MESSAGE' } }

        result = run(omit_test)

        expect(result.result).to eq('omit')
        expect(result.result_message).to eq(message)
      end

      it 'does not omit if an assertion does not fail in the block' do
        omit_test.run { omit { assert true, 'OMIT_MESSAGE' } }

        result = run(omit_test)

        expect(result.result).to eq('pass')
      end
    end
  end
end
