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

  describe '#services_names' do
    context 'when test kit services are running' do
      before do
        stub_request(:get, "#{fhirpath_url}/version").to_return(status: 200)
      end

      it 'only returns hl7 validator service' do
        expect(evaluate.services_names.strip).to eq('hl7_validator_service')
      end
    end

    context 'when test kit services are not running' do
      before do
        stub_request(:get, "#{fhirpath_url}/version").to_timeout
      end

      it 'returns hl7 validator service and fhirpath service' do
        expect(evaluate.services_names.strip).to eq('hl7_validator_service fhirpath')
      end
    end
  end
end
