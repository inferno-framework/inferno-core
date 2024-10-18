require 'rspec'
require 'inferno/apps/cli/new'

PACKAGE_FIXTURE = File.expand_path('../../fixtures/small_package.tgz', __dir__)

RSpec.describe Inferno::CLI::New do
  around do |test|
    Dir.mktmpdir do |tmpdir|
      FileUtils.chdir(tmpdir) do
        test.run
      end
    end
  end

  [
    %w[test-fhir-app],
    %w[test-fhir-app --author ABC],
    %w[test-fhir-app --author ABC --author DEF],
    %W[test-fhir-app --implementation-guide file://#{PACKAGE_FIXTURE}],
    %W[test-fhir-app --implementation-guide file://#{PACKAGE_FIXTURE} --implementation-guide file://#{PACKAGE_FIXTURE}],
    %W[test-fhir-app --author ABC --implementation-guide file://#{PACKAGE_FIXTURE}]
  ].each do |cli_args|
    cli_args.append('--quiet')
    cli_args.append('--skip-bundle')

    it "runs inferno new #{cli_args.join(' ')}" do
      expect { described_class.start(cli_args) }.to_not raise_error

      expect(Dir).to exist('test-fhir-app')
      expect(File).to exist('test-fhir-app/Gemfile')
      expect(File).to exist('test-fhir-app/test_fhir_app.gemspec')
      expect(File).to exist('test-fhir-app/lib/test_fhir_app.rb')

      if cli_args.include? '--author'
        expect(File.read('test-fhir-app/test_fhir_app.gemspec')).to match(/authors\s*=.*ABC/)
      end

      if cli_args.count('--author') == 2
        expect(File.read('test-fhir-app/test_fhir_app.gemspec')).to match(/authors\s*=.*ABC.*DEF/)
      end

      if cli_args.count('--implementation-guide') == 1
        expect(File).to exist('test-fhir-app/lib/test_fhir_app/igs/package.tgz')
      end

      if cli_args.count('--implementation-guide') == 2
        expect(File).to exist('test-fhir-app/lib/test_fhir_app/igs/package_0.tgz')
        expect(File).to exist('test-fhir-app/lib/test_fhir_app/igs/package_1.tgz')
      end
    end
  end
end
