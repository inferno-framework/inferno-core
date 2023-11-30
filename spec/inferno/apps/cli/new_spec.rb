require 'rspec'
require 'inferno/apps/cli/new'

ABSOLUTE_PATH_TO_IG = File.expand_path('../../../fixtures/small_package.tgz', __dir__)

RSpec.describe Inferno::CLI::New do # rubocop:disable RSpec/FilePath
  before do |_test|
    stub_request(:get, %r{https?://.*package.tgz})
      .to_return(status: 200, body: File.read(ABSOLUTE_PATH_TO_IG), headers: { 'Content-Type' => 'application/gzip' })
  end

  around do |test|
    Dir.mktmpdir do |tmpdir|
      FileUtils.chdir(tmpdir) do
        test.run
      end
    end
  end

  [
    %w[test-fhir-app],
    %w[test-fhir-app --implementation-guide https://build.fhir.org/ig/HL7/fhir-udap-security-ig/],
    %w[test-fhir-app --implementation-guide https://build.fhir.org/ig/HL7/fhir-udap-security-ig/index.html],
    %w[test-fhir-app --implementation-guide https://build.fhir.org/ig/HL7/fhir-udap-security-ig/package.tgz],
    %W[test-fhir-app --implementation-guide #{ABSOLUTE_PATH_TO_IG}],
    %w[test-fhir-app --author ABC --author DEF]
  ].each do |cli_args|
    cli_args.append('--quiet')

    it "runs inferno new #{cli_args.join(' ')}" do
      expect { described_class.start(cli_args) }.to_not raise_error

      expect(Dir).to exist('test-fhir-app')
      expect(File).to exist('test-fhir-app/Gemfile')
      expect(File).to exist('test-fhir-app/test_fhir_app.gemspec')
      expect(File).to exist('test-fhir-app/lib/test_fhir_app.rb')

      if cli_args.include? '--implementation-guide'
        expect(File).to exist('test-fhir-app/lib/test_fhir_app/igs/package.tgz')
      end

      if cli_args.include? '--author'
        expect(File.read('test-fhir-app/test_fhir_app.gemspec')).to match(/authors\s*=.*ABC.*DEF/)
      end
    end
  end
end
