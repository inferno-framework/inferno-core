require_relative '../../../../lib/inferno/apps/cli/execute/json_outputter'
require_relative 'outputter_spec'

RSpec.describe Inferno::CLI::Execute::JSONOutputter do
  let(:instance) { described_class.new }
  let(:options) { { outputter: 'json', verbose: false } }

  include_examples 'outputter_spec', described_class

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
