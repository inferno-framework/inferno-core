require 'rspec'
require 'inferno/apps/cli/new/new'

ABSOLUTE_PATH_TO_IG = File.expand_path('../../../fixtures/small_package.tgz', __dir__)

RSpec.describe Inferno::CLI::New do

  # Wrap all 'it' examples in a temp dir
  around do |test|
    Dir.mktmpdir do |tmpdir|
      FileUtils.chdir(tmpdir) do
        WebMock.allow_net_connect!
        test.run
        WebMock.disable_net_connect!
      end
    end
  end

  # test various `inferno new ...` options
  [
    %w[test-fhir-app],
    %w[test_fhir_app],
    %w[TestFhirApp],
    %w[test-fhir-app --implementation-guide https://build.fhir.org/ig/HL7/US-Core/],
    %w[test-fhir-app --implementation-guide https://build.fhir.org/ig/HL7/US-Core/index.html],
    %w[test-fhir-app --implementation-guide https://build.fhir.org/ig/HL7/US-Core/package.tgz],
    %W[test-fhir-app --implementation-guide #{ABSOLUTE_PATH_TO_IG}],
    %w[test-fhir-app --author ABC --author DEF]
  ].each do |cli_args|
    cli_args.append('--quiet')

    it "runs inferno new #{cli_args.join(' ')}" do
      expect { Inferno::CLI::New.start(cli_args) }.to_not raise_error

      expect(Dir).to exist('test-fhir-app')
      expect(File).to exist('test-fhir-app/Gemfile')
      expect(File).to exist('test-fhir-app/test_fhir_app.gemspec')
      expect(File).to exist('test-fhir-app/lib/test_fhir_app.rb')
      expect(File.read('test-fhir-app/lib/test_fhir_app.rb')).to include('module TestFhirApp')
      expect(File.read('test-fhir-app/lib/test_fhir_app.rb')).to include('id :test_fhir_app_test_suite')
      expect(File.read('test-fhir-app/lib/test_fhir_app.rb')).to include("title 'Test Fhir App Test Suite'")
      expect(File.read('test-fhir-app/README.md')).to match(/^Test fhir app/)

      if cli_args.include? '--implementation-guide'
        expect(File).to exist('test-fhir-app/lib/test_fhir_app/igs/package.tgz')
      end

      if cli_args.include? '--author'
        expect(File.read('test-fhir-app/test_fhir_app.gemspec')).to match(/authors\s*=.*ABC.*DEF/)
      end
    end
  end
end
