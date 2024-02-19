require 'thor'
require_relative '../../../lib/inferno/utils/ig_downloader'

PACKAGE_FIXTURE = File.expand_path('../../fixtures/small_package.tgz', __dir__)

def with_temp_path(name)
  path = File.join(Inferno::Application.root, 'tmp', "rspec-#{name.sum}.tmp")
  yield(path)
  File.delete(path) if File.exist?(path)
end

RSpec.describe Inferno::Utils::IgDownloader do
  let(:ig_downloader_class) do
    Class.new do
      include Thor::Base
      include Thor::Actions
      include Inferno::Utils::IgDownloader
      attr_accessor :library_name

      source_root Inferno::Application.root
    end
  end
  let(:ig_downloader) do
    ig_downloader_instance = ig_downloader_class.new
    ig_downloader_instance.library_name = 'udap'
    ig_downloader_instance
  end
  let(:package_binary) { File.read(PACKAGE_FIXTURE) }

  describe '#ig_path' do
    it 'builds correct path to IGs' do
      expect(ig_downloader.ig_path).to eq('lib/udap/igs')
    end
  end

  describe '#ig_file' do
    it 'builds correct IG file path' do
      expect(ig_downloader.ig_file).to eq('lib/udap/igs/package.tgz')
    end

    it 'suffixes IG file path' do
      expect(ig_downloader.ig_file(99)).to eq('lib/udap/igs/package_99.tgz')
    end
  end

  context 'with IG by canonical name' do
    let(:canonical) { 'hl7.fhir.us.udap-security@1.0.0' }
    let(:resolved_url) do
      'https://packages.simplifier.net/hl7.fhir.us.udap-security/-/hl7.fhir.us.udap-security-1.0.0.tgz'
    end

    describe 'FHIR_PACKAGE_NAME_REG_EX' do
      it 'matches given canonical name' do
        expect(canonical).to match(Inferno::Utils::IgDownloader::FHIR_PACKAGE_NAME_REG_EX)
      end
    end

    describe '#ig_registry_url' do
      it 'returns correct registry url' do
        expect(ig_downloader.ig_registry_url(canonical)).to eq(resolved_url)
      end

      it 'raises exception if missing version' do
        expect do
          ig_downloader.ig_registry_url('hl7.fhir.us.udap-security')
        end.to raise_error(Inferno::Utils::IgDownloader::Error)
      end
    end

    describe '#load_ig' do
      it 'successfully downloads IG' do
        stub_request(:get, 'https://packages.simplifier.net/hl7.fhir.us.udap-security/-/hl7.fhir.us.udap-security-1.0.0.tgz')
          .to_return(body: package_binary)

        with_temp_path('ig-downloader-canonical') do |temp_path|
          allow(ig_downloader).to receive(:ig_file).and_return(temp_path)
          ig_downloader.load_ig(canonical, nil, { verbose: false })
          expect(File.read(temp_path)).to eq(package_binary)
        end
      end
    end
  end

  %w[
    https://build.fhir.org/ig/HL7/fhir-udap-security-ig/package.tgz
    https://build.fhir.org/ig/HL7/fhir-udap-security-ig/
    https://build.fhir.org/ig/HL7/fhir-udap-security-ig/index.html
    https://build.fhir.org/ig/HL7/fhir-udap-security-ig/downloads.html
    http://build.fhir.org/ig/HL7/fhir-udap-security-ig/
  ].each do |url|
    context "with IG by http URL #{url}" do
      describe 'HTTP_URI_REG_EX' do
        it 'matches given url' do
          expect(url).to match(Inferno::Utils::IgDownloader::HTTP_URI_REG_EX)
        end
      end

      describe 'FHIR_PACKAGE_NAME_REG_EX' do
        it 'does not match given url' do
          expect(url).to_not match(Inferno::Utils::IgDownloader::FHIR_PACKAGE_NAME_REG_EX)
        end
      end

      describe '#ig_http_url' do
        it 'normalizes to a package.tgz url' do
          expect(ig_downloader.ig_http_url(url)).to match(%r{https?://build.fhir.org/ig/HL7/fhir-udap-security-ig/package.tgz})
        end
      end

      describe '#load_ig' do
        it 'downloads IG' do
          stub_request(:get, %r{https?://build.fhir.org}).to_return(body: package_binary)
          with_temp_path("ig-downloader-#{url}") do |temp_path|
            allow(ig_downloader).to receive(:ig_file).and_return(temp_path)
            ig_downloader.load_ig(url, nil, { verbose: false })
            expect(File.read(temp_path)).to eq(package_binary)
          end
        end
      end
    end
  end

  context 'with IG by absolute file path' do
    let(:absolute_path) { "file://#{PACKAGE_FIXTURE}" }

    describe 'FILE_URI_REG_EX' do
      it 'matches given file uri' do
        expect(absolute_path).to match(Inferno::Utils::IgDownloader::FILE_URI_REG_EX)
      end
    end

    describe 'HTTP_URI_REG_EX' do
      it 'does not match given file uri' do
        expect(absolute_path).to_not match(Inferno::Utils::IgDownloader::HTTP_URI_REG_EX)
      end
    end

    describe 'FHIR_PACKAGE_NAME_REG_EX' do
      it 'does not match given file uri' do
        expect(absolute_path).to_not match(Inferno::Utils::IgDownloader::FHIR_PACKAGE_NAME_REG_EX)
      end
    end

    describe '#load_ig' do
      it 'downloads IG' do
        with_temp_path('ig-downloader-file') do |temp_path|
          allow(ig_downloader).to receive(:ig_file).and_return(temp_path)
          ig_downloader.load_ig(absolute_path, nil, { verbose: false })
          expect(File.read(temp_path)).to eq(package_binary)
        end
      end
    end
  end

  describe '#load_ig' do
    it 'with bad input raises exception' do
      expect { ig_downloader.load_ig('bad') }.to raise_error(Inferno::Utils::IgDownloader::Error)
    end

  end
end
