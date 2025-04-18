require 'rspec'
require 'thor'
require 'inferno/apps/cli/services'

def setup_mock_test_kit(test_kit_path)
  File.open(File.join(test_kit_path, 'tmp_test_kit.gemspec'), 'w') do |f|
    f.write <<~GEMSPEC
      Gem::Specification.new do |spec|
        spec.name          = 'tmp_test_kit'
        spec.version       = '0.0.0'
        spec.authors       = ['Inferno Core Team']
        spec.summary       = 'RSpec Testing'
        spec.metadata['inferno_test_kit'] = 'true'
      end
    GEMSPEC
  end

  gemfile = File.join(test_kit_path, 'Gemfile')
  File.write(gemfile, '')

  compose_path = File.join(test_kit_path, 'docker-compose.background.yml')  
  File.write(compose_path, '')
end

RSpec.describe Inferno::CLI::Services do
  let(:services_cli) { described_class.new }

  context '#path' do
    context 'outside of test kit without bundle exec' do
      before(:each) do
        allow(services_cli).to receive(:bundle_exec?).and_return(false)
      end

      it 'outputs global docker compose path' do
        global_compose_path = File.absolute_path('../../../lib/inferno/apps/cli/services/docker-compose.global.yml', __dir__)
        expect { described_class.new.path }.to output(global_compose_path + "\n").to_stdout
      end
    end

    context 'inside test kit with bundle exec' do
      around(:each) do |example|
        Dir.mktmpdir do |tmp_test_kit|
          Dir.chdir(tmp_test_kit) do
            setup_mock_test_kit(tmp_test_kit)
            example.run
          end
        end
      end

      before(:each) do
        allow(services_cli).to receive(:bundle_exec?).and_return(true)
      end

      let(:compose_path_output) { File.absolute_path('docker-compose.background.yml', Dir.pwd) + "\n" }

      it 'outputs background docker compose path' do
        expected_output = File.absolute_path('docker-compose.background.yml', Dir.pwd) + "\n"
        expect { services_cli.path }.to output(expected_output).to_stdout
      end
  
      it 'in subfolder outputs background docker compose path' do
        #require 'pry'
        #binding.pry

        #pp :DEBUGGING
        #services_cli.path

        expected_output = File.absolute_path('docker-compose.background.yml', Dir.pwd) + "\n"
        Dir.mkdir('lib')
        Dir.chdir('lib') do

        pp Dir.pwd
        pp Dir.glob('*')
        pp Dir.glob('../*')
        services_cli.path


          expect { services_cli.path }.to output(expected_output).to_stdout
        end
      end
    end
  end
end
