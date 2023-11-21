require 'rspec'
require 'fileutils'
require 'inferno/apps/cli/new/new'


RSpec.describe Inferno::CLI::New do

  ABSOLUTE_PATH_TO_IG = File.expand_path(__FILE__, '../../../fixtures/small_package.tgz')
    
  # Wrap all 'it' examples in a temp dir
  around(:each) do |test|
    Dir.mktmpdir do |tmpdir|
      FileUtils.chdir(tmpdir) do
        test.run
      end
    end
  end

  # NOTE: WebMock blocks real HTTP requests for some reason: https://stackoverflow.com/a/22976546
  # Re-enabling it for testing online IG pull
  WebMock.allow_net_connect!

  # test various `inferno new ...`
  [
    %w(spec-1 --quiet),
    %w(spec-1 --implementation-guide https://build.fhir.org/ig/HL7/US-Core/ --quiet),
    %w(spec-1 --implementation-guide https://build.fhir.org/ig/HL7/US-Core/index.html --quiet),
    %w(spec-1 --implementation-guide https://build.fhir.org/ig/HL7/US-Core/package.tgz --quiet),
    %W(spec-1 --implementation-guide #{ABSOLUTE_PATH_TO_IG} --quiet),
    %w(spec-1 --author ABC --author DEF --quiet)
  ].each do |cli_args|
    it "generates Inferno project with #{cli_args}" do
      expect { Inferno::CLI::New.start(cli_args) }.not_to raise_error

      expect(Dir).to exist('spec-1')
      expect(File).to exist('spec-1/Gemfile')
      expect(File).to exist('spec-1/spec_1.gemspec')
      expect(File).to exist('spec-1/lib/spec_1.rb')
      
      if cli_args.include? '--implementation-guide'
        expect(File).to exist('spec-1/lib/spec_1/igs/package.tgz')
      end

      if cli_args.include? '--author'
        expect(File.read('spec-1/spec_1.gemspec')).to match(/authors\s*=.*ABC.*DEF/)
      end
    end
  end

  # test `inferno new ... --pretend`
  it 'does not create Inferno project with ["spec-1", "--pretend", "--quiet"]' do
    expect { Inferno::CLI::New.start(%w(spec-1 --pretend --quiet)) }.not_to raise_error

    expect(Dir).not_to exist('spec-1')
  end

  # test `inferno new ... --skip` and `inferno new ... --force`
  it 'asdf' do
    # TODO
  end

end
