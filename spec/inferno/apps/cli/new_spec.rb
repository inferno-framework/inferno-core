require 'rspec'
require 'fileutils'
require 'inferno/apps/cli/new/new'
# require_relative '../../../../lib/inferno/apps/cli/new/new'

RSpec.describe Inferno::CLI::New do
  it "works" do
    Dir.mktmpdir do |tmpdir|
      FileUtils.chdir(tmpdir) do
        expect { Inferno::CLI::New.start(["inferno_new_spec"]) }.not_to raise_error 
      end
    end
  end
end
