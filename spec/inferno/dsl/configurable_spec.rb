class ConfigurableTestClass
  extend Inferno::DSL::Configurable
end

RSpec.describe Inferno::DSL::Configurable do
  describe '.config' do
    let(:runnable) do
      ConfigurableTestClass.tap do |klass|
        klass.instance_variable_set(:@config, nil)
      end
    end

    let(:new_config) do
      {
        inputs: { input1: { name: :input2 } }
      }
    end

    context 'when there is no existing configuration' do
      it 'creates a config from a hash' do
        runnable.config(new_config)

        expect(runnable.config.configuration).to eq(new_config)
      end

      it 'creates a config from a config object' do
        config_object = described_class::Configuration.new(new_config)
        runnable.config(config_object)

        expect(runnable.config.configuration).to eq(new_config)
      end
    end

    context 'when there is an existing configuration' do
      it 'merges the configurations' do
        existing_config = {
          inputs: {
            input1: { name: :input1, type: 'textarea' }
          }
        }

        expected_config = {
          inputs: {
            input1: { name: :input2, type: 'textarea' }
          }
        }

        config_object = described_class::Configuration.new(existing_config)
        runnable.instance_variable_set(:@config, config_object)
        runnable.config(new_config)

        expect(runnable.config.configuration).to eq(expected_config)
      end
    end
  end

  describe Inferno::DSL::Configurable::Configuration do
    let(:config) { described_class.new }

    describe '#add_input' do
      context 'with no existing input' do
        it 'adds an input with a default config' do
          identifier = :input1
          config.add_input(identifier)
          expected_config = config.default_input_config(identifier)

          expect(config.input_config(identifier)).to eq(expected_config)
        end

        it 'adds an input with a config' do
          identifier = :input1
          input_config = { type: 'textarea' }
          config.add_input(identifier, input_config)
          expected_config = { name: :input1 }.merge(input_config)

          expect(config.input_config(identifier)).to eq(expected_config)
        end
      end

      context 'with an existing input' do
        it 'leaves the config unchanged if no new config is provided' do
          existing_config = { name: :input2, type: 'textarea' }
          identifier = :input1
          config.add_input(identifier, existing_config)
          config.add_input(identifier)

          expect(config.input_config(identifier)).to eq(existing_config)
        end

        it 'updates the config if a new config is provided' do
          existing_config = { name: :input2, type: 'textarea' }
          new_config = { name: :input3 }
          identifier = :input1
          config.add_input(identifier, existing_config)
          config.add_input(identifier, new_config)

          expect(config.input_config(identifier)).to eq(existing_config.merge(new_config))
        end
      end
    end

    describe '#add_output' do
      it 'adds an output with a default config' do
        identifier = :output1
        config.add_output(identifier)
        expected_config = config.default_output_config(identifier)

        expect(config.output_config(identifier)).to eq(expected_config)
      end
    end

    describe '#add_request' do
      it 'adds an request with a default config' do
        identifier = :request1
        config.add_request(identifier)
        expected_config = config.default_request_config(identifier)

        expect(config.request_config(identifier)).to eq(expected_config)
      end
    end
  end
end
