require 'rspec'
require 'inferno/apps/cli/new/new'


RSpec.describe Inferno::CLI::New do

  ABSOLUTE_PATH_TO_IG = File.expand_path('../../../../fixtures/small_package.tgz', __FILE__)
    
  # Wrap all 'it' examples in a temp dir
  around(:each) do |test|
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
    %w(test-fhir-app --quiet),
    %w(test_fhir_app --quiet),
    %w(TestFHIRApp --quiet),
    %w(TestFhirApp --quiet),
    %w(test-fhir-app --implementation-guide https://build.fhir.org/ig/HL7/US-Core/ --quiet),
    %w(test-fhir-app --implementation-guide https://build.fhir.org/ig/HL7/US-Core/index.html --quiet),
    %w(test-fhir-app --implementation-guide https://build.fhir.org/ig/HL7/US-Core/package.tgz --quiet),
    %W(test-fhir-app --implementation-guide #{ABSOLUTE_PATH_TO_IG} --quiet),
    %w(test-fhir-app --author ABC --author DEF --quiet)
  ].each do |cli_args|
    it "generates Inferno project with #{cli_args}" do
      expect { Inferno::CLI::New.start(cli_args) }.not_to raise_error

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

  # test `inferno new ... --pretend`
  it 'does not generate Inferno project with ["test-fhir-app", "--pretend", "--quiet"]' do
    expect { Inferno::CLI::New.start(%w(test-fhir-app --pretend --quiet)) }.not_to raise_error

    expect(Dir).not_to exist('test-fhir-app')
  end

end
