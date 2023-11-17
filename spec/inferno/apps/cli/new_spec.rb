require 'rspec'
require 'fileutils'
require 'inferno/apps/cli/new/new'


RSpec.describe Inferno::CLI::New do

#  def run_generator(*args)
#    Inferno::CLI::New.start(args)
#  end

  around(:each) do |test|
    Dir.mktmpdir do |tmpdir|
      FileUtils.chdir(tmpdir) do
        test.run
      end
    end
  end


  it 'works' do
    expect { Inferno::CLI::New.start(['spec_1', '--quiet']) }.not_to raise_error

    expect(Dir).to exist('spec-1')
    expect(File).to exist('spec-1/Gemfile')
    expect(File).to exist('spec-1/spec_1.gemspec')
  end


  shared_examples 'working inferno project' do |name, lib_name|
    it 'has root directory' do
      expect(Dir).to exist(name)
    end

    it 'has Gemfile' do
      expect(File).to exist("#{name}/Gemfile")
    end

    it 'has gemspec' do
      expect(File).to exist("#{name}/#{lib_name}.gemspec")
    end
  end

  context 'TODO' do

#
#    it 'with an http implementation guide should create an Inferno project' do
#      expect { Inferno::CLI::New.start(['spec_2', '--implementation-guide', 'http://build.fhir.org/ig/HL7/US-Core/']) }.not_to raise_error
#
#      expect { File.directory?('spec-2') }.to be true
#      expect { File.exist?('spec-2/Gemfile') }.to be true
#      expect { File.exist?('spec-2/spec_2.gemspec') }.to be true
#    end
#
#    it 'with an absolute path to an implementation guide should create an Inferno project' do
#      absolute_path_to_ig = File.expand_path('../../../../fixtures/small_package.tgz', __FILE__)
#
#      expect { Inferno::CLI::New.start(['spec_3', '--implementation-guide', absolute_path_to_ig, '--quiet']) }.not_to raise_error
#
#      expect { File.directory?('spec-3') }.to be true
#      expect { File.exist?('spec-3/Gemfile') }.to be true
#      expect { File.exist?('spec-3/spec_1.gemspec') }.to be true
#    end
#
  end

end
