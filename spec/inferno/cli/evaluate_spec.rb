require_relative '../../../lib/inferno/apps/cli/evaluate'

RSpec.describe Inferno::CLI::Evaluate do
  let(:evaluate) { described_class.new }
  let(:compose_file) { File.expand_path('../../../lib/inferno/apps/cli/evaluate/docker-compose.evaluate.yml', __dir__) }
  let(:fhirpath_url) { 'https://example.com/fhirpath' }

  describe '#services_base_command' do
    it 'returns the correct prefix for docker compose command' do
      expect(evaluate.services_base_command).to eq("docker compose -f #{compose_file}")
    end
  end
end
