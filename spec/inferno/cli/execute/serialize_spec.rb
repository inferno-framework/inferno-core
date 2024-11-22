require_relative '../../../../lib/inferno/apps/cli/execute/serialize'

RSpec.describe Inferno::CLI::Execute::Serialize do
  let(:dummy_class) { Class.new { include Inferno::CLI::Execute::Serialize } }
  let(:instance) { dummy_class.new }

  describe '#serialize' do
    let(:test_results) { create_list(:result, 2) }

    it 'handles an array of test results without raising exception' do
      expect { instance.serialize(test_results) }.to_not raise_error(StandardError)
    end

    it 'returns JSON' do
      expect { JSON.parse(instance.serialize(test_results)) }.to_not raise_error(StandardError)
    end
  end
end
