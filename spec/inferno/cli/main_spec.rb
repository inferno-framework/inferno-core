require 'rspec'
require 'thor'
require 'inferno/apps/cli/main'
require 'inferno/version'

RSpec.describe Inferno::CLI::Main do
  context 'with version command' do
    it 'outputs current Inferno version' do
      expect { described_class.new.version }.to output("Inferno Core v#{Inferno::VERSION}\n").to_stdout
    end
  end
end
