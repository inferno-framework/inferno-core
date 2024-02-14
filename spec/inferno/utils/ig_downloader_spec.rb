require 'thor'
require_relative '../../../lib/inferno/utils/ig_downloader'

RSpec::Matchers.define :case_match do |expected|
  match do |actual|
    expected === actual # rubocop:disable Style/CaseEquality
  end
end

RSpec::Matchers.define :be_same_file_as do |expected|
  match do |actual|
    expected.rewind.read == actual.rewind.read
  end
end

PACKAGE_FIXTURE = File.expand_path('../../fixtures/small_package.tgz', __dir__)

RSpec.describe Inferno::Utils::IgDownloader do
  let(:dummy_class) do
    Class.new do
      include Thor::Base
      include Thor::Actions
      include Inferno::Utils::IgDownloader
      attr_accessor :library_name
    end
  end
  let(:dummy) do
    dummy_instance = dummy_class.new
    dummy_instance.library_name = 'udap'
    dummy_instance
  end
  let(:package_fixture) { File.open(PACKAGE_FIXTURE, 'r') }
  let(:tempdir) { File.join(Inferno::Application.root, 'tmp') }

  it 'builds correct path to IGs' do
    expect(dummy.ig_path).to eq('lib/udap/igs')
  end

  it 'builds correct IG file path' do
    expect(dummy.ig_file).to eq('lib/udap/igs/package.tgz')
  end

  it 'suffixes IG file path' do
    expect(dummy.ig_file(99)).to eq('lib/udap/igs/package_99.tgz')
  end

  context 'with IG by canonical name' do
    let(:canonical) { 'hl7.fhir.us.udap-security@1.0.0' }
    let(:resolved_url) do
      'https://packages.simplifier.net/hl7.fhir.us.udap-security/-/hl7.fhir.us.udap-security-1.0.0.tgz'
    end
    let(:tempfile) { Tempfile.new('rspec-ig-downloader-canonical-', tempdir) }

    before do
      stub_request(:get, "https://packages.simplifier.net/hl7.fhir.us.udap-security/-/hl7.fhir.us.udap-security-1.0.0.tgz").
        with(
          headers: {
       	    'Accept'=>'*/*',
       	    'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
       	    'User-Agent'=>'Ruby'
          }).
        to_return(status: 200, body: package_fixture, headers: {'Content-Disposition'=>'attachment'})
    end

    it 'matches fhir package name regex' do
      expect(canonical).to case_match(Inferno::Utils::IgDownloader::FHIR_PACKAGE_NAME)
    end

    it 'returns correct registry url' do
      expect(dummy.ig_registry_url(canonical)).to eq(resolved_url)
    end

    it 'raises exception if missing version' do
      expect { dummy.ig_registry_url('hl7.fhir.us.udap-security') }.to raise_error(Inferno::Utils::IgDownloader::Error)
    end

    it 'downloads IG' do
      allow(dummy).to receive(:ig_file).and_return(tempfile.path)
      dummy.load_ig(canonical)
      expect { tempfile }.to be_same_file_as( package_fixture )
    end
  end

  %w[
    https://build.fhir.org/ig/HL7/fhir-udap-security-ig/package.tgz
    https://build.fhir.org/ig/HL7/fhir-udap-security-ig/
    https://build.fhir.org/ig/HL7/fhir-udap-security-ig/index.html
    http://build.fhir.org/ig/HL7/fhir-udap-security-ig/
  ].each do |url|
    context "with IG by http URL #{url}" do
      let(:tempfile) { Tempfile.new('rspec-ig-downloader-http-', tempdir) }

      it 'matches http uri regex' do
        expect(url).to case_match(Inferno::Utils::IgDownloader::HTTP_URI)
      end

      it 'does not match fhir package name regex' do
        expect(url).to_not case_match(Inferno::Utils::IgDownloader::FHIR_PACKAGE_NAME)
      end

      it 'normalizes to a package.tgz url' do
        expect(dummy.ig_http_url(url)).to match(%r{https?://build.fhir.org/ig/HL7/fhir-udap-security-ig/package.tgz})
      end

      it 'downloads IG' do
        stub_request(:get, %r{https?://build.fhir.org}).to_return(body: package_fixture)
        allow(dummy).to receive(:ig_file).and_return(tempfile.path)
        dummy.load_ig(url)
        expect { tempfile }.to be_same_file_as( package_fixture )
      end
    end
  end

  context 'with IG by absolute file path' do
    let(:absolute_path) { "file://#{PACKAGE_FIXTURE}" }
    let(:tempfile) { Tempfile.new('rspec-ig-downloader-file', File.join(Inferno::Application.root,'tmp')) }

    it 'matches file regex' do
      expect(absolute_path).to case_match(Inferno::Utils::IgDownloader::FILE_URI)
    end

    it 'does not match http uri regex' do
      expect(absolute_path).to_not case_match(Inferno::Utils::IgDownloader::HTTP_URI)
    end

    it 'does not match fhir package name regex' do
      expect(absolute_path).to_not case_match(Inferno::Utils::IgDownloader::FHIR_PACKAGE_NAME)
    end

    it 'downloads IG' do
      allow(dummy).to receive(:ig_file).and_return(tempfile.path)
      dummy.load_ig(absolute_path)
      expect { tempfile }.to be_same_file_as( package_fixture )
    end
  end

  it 'with bad input raises exception' do
    expect { dummy.load_ig('bad') }.to raise_error(Inferno::Utils::IgDownloader::Error)
  end
end
