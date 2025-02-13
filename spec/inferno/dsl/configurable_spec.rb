class ConfigurableTestClass
  extend Inferno::DSL::Configurable

  def self.all_children
    @all_children ||= []
  end
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
      let(:expected_config) do
        {
          inputs: { input1: Inferno::Entities::Input.new(name: :input2, type: 'text') }
        }
      end

      it 'creates a config from a hash' do
        runnable.config(new_config)

        expect(runnable.config.configuration).to eq(expected_config)
      end

      it 'creates a config from a config object' do
        config_object = described_class::Configuration.new(new_config)
        runnable.config(config_object)

        expect(runnable.config.configuration).to eq(expected_config)
      end
    end

    context 'when there is an existing configuration' do
      it 'merges the configurations' do
        existing_config = {
          inputs: {
            input1: Inferno::Entities::Input.new(name: :input1, type: 'textarea')
          }
        }

        expected_config = {
          inputs: {
            input1: Inferno::Entities::Input.new(name: :input2, type: 'textarea')
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
          expected_input = Inferno::Entities::Input.new(**config.default_input_params(identifier))

          expect(config.input(identifier)).to eq(expected_input)
        end

        it 'adds an input with a config' do
          identifier = :input1
          input = { type: 'textarea' }
          config.add_input(identifier, input)
          expected_input = Inferno::Entities::Input.new(name: :input1, **input)

          expect(config.input(identifier)).to eq(expected_input)
        end
      end

      context 'with an existing input' do
        it 'leaves the config unchanged if no new config is provided' do
          existing_input = Inferno::Entities::Input.new(name: :input2, type: 'textarea')
          identifier = :input1
          config.add_input(identifier, existing_input.to_hash)
          config.add_input(identifier)

          expect(config.input(identifier)).to eq(existing_input)
        end

        it 'updates the config if a new config is provided' do
          existing_config = { name: :input2, type: 'textarea' }
          new_config = { name: :input3 }
          identifier = :input1
          config.add_input(identifier, existing_config)
          config.add_input(identifier, new_config)

          expect(config.input(identifier)).to eq(Inferno::Entities::Input.new(**existing_config.merge(new_config)))
        end
      end

      context 'with auth_info' do
        it 'merges individual component options' do
          identifier = :auth_info_merge

          list_options = [
            {
              label: 'Public',
              value: 'public'
            },
            {
              label: 'Confidential Symmetric',
              value: 'symmetric'
            }
          ]
          existing_component_config = [
            {
              name: :use_discovery,
              locked: true
            },
            {
              name: :auth_type,
              options: {
                list_options:
              }
            },
            {
              name: :pkce_support,
              default: 'enabled'
            }
          ]

          new_component_config = [
            {
              name: :auth_type,
              default: 'symmetric'
            },
            {
              name: :pkce_support,
              locked: true
            }
          ]

          existing_config = {
            type: 'auth_info',
            options: {
              components: existing_component_config
            }
          }
          new_config = {
            type: 'auth_info',
            options: {
              components: new_component_config
            }
          }

          config.add_input(identifier, existing_config)
          config.add_input(identifier, new_config)

          final_components = config.input(identifier).options[:components]

          expect(final_components.length).to eq(3)

          auth_type_component = final_components.find { |component| component[:name] == :auth_type }

          expect(auth_type_component[:default]).to eq('symmetric')
          expect(auth_type_component[:options][:list_options].length).to eq(2)

          pkce_component = final_components.find { |component| component[:name] == :pkce_support }

          expect(pkce_component[:default]).to eq('enabled')
          expect(pkce_component[:locked]).to be(true)

          discovery_component = final_components.find { |component| component[:name] == :use_discovery }
          expect(discovery_component).to eq(existing_component_config.first)
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
