require_relative '../../../lib/inferno/apps/cli/evaluate'

RSpec.describe Inferno::CLI::Evaluate do
  let(:evaluate) { described_class.new }
  let(:compose_file) { File.expand_path('../../../lib/inferno/apps/cli/evaluate/docker-compose.evaluate.yml', __dir__) }
  let(:fhirpath_url) { 'https://example.com/fhirpath' }
  let(:ig_path) { './spec/fixtures/small_package.tgz' }
  let(:data_path) { nil }

  describe '#services_base_command' do
    it 'returns the correct prefix for docker compose command' do
      expect(evaluate.services_base_command).to eq("docker compose -f #{compose_file}")
    end
  end

  describe '#evaluate' do
    let(:config_path) { nil }
    let(:options) { {} }

    it 'evaluates with default configuration' do
      expect do
        evaluate.evaluate(ig_path, data_path, config_path, options)
      end.to output(/SUCCESS/).to_stdout
    end

    context 'with custom configuration' do
      let(:config_path) { './spec/fixtures/test_evaluator_config.yml' }

      it 'evaluates with custom configuration' do
        expect do
          evaluate.evaluate(ig_path, data_path, config_path, options)
        end.to output(/SUCCESS/).to_stdout
      end
    end

    context 'with invalid configuration path' do
      let(:config_path) { './non_existent_config.yml' }

      it 'raises an error' do
        expect do
          evaluate.evaluate(ig_path, data_path, config_path, options)
        end.to raise_error(RuntimeError, /does not exist/)
      end
    end
  end
end
