RSpec.describe Inferno::Repositories::IGs do # rubocop:disable RSpec/SpecFilePathFormat
  let(:repo) { described_class.new }

  let(:uscore3_package) { File.expand_path('../../fixtures/uscore311.tgz', __dir__) }

  let(:temp_package_cache) do
    tpc = File.join(Dir.mktmpdir('packagecache'), 'packages')
    FileUtils.mkdir_p(tpc)
    tpc
  end

  # start and each test with a clean repository
  def clear_repo
    repo.all.clear
    repo.all_by_id.clear
  end

  before do
    clear_repo
  end

  after do
    clear_repo
  end

  def expect_spot_check_uscore3(ig)
    # simple spot check, see more detailed load testing in entities/ig_spec
    expect(ig.profiles.length).to eq(26)
    expect(ig.profiles.map(&:resourceType).uniq).to eq(['StructureDefinition'])
    expect(ig.profiles.map(&:id)).to include('us-core-patient', 'us-core-condition',
                                             'head-occipital-frontal-circumference-percentile')
  end

  describe '#find_or_load' do
    it 'loads an IG from file' do
      ig = repo.find_or_load(uscore3_package)

      expect(ig.id).to eq('hl7.fhir.us.core#3.1.1')
      expect(ig.source_path).to eq(uscore3_package)

      expect_spot_check_uscore3(ig)
    end

    it 'loads an IG from user package cache' do
      allow(repo).to receive(:user_package_cache).and_return(temp_package_cache)

      uscore3_dir = File.join(temp_package_cache, 'hl7.fhir.us.core#3.1.1')
      FileUtils.mkdir_p(uscore3_dir)
      system "tar -xzf #{uscore3_package} --directory #{uscore3_dir}"

      ig = repo.find_or_load('hl7.fhir.us.core#3.1.1')

      expect(ig.id).to eq('hl7.fhir.us.core#3.1.1')
      expect(ig.source_path).to eq(uscore3_dir)
      expect_spot_check_uscore3(ig)
    end

    it 'downloads and caches an IG' do
      allow(repo).to receive(:user_package_cache).and_return(temp_package_cache)
      download_url = 'https://packages.fhir.org/hl7.fhir.us.core/-/hl7.fhir.us.core-3.1.1.tgz'
      stub_request(:get, download_url)
        .to_return(status: 200, body: File.open(uscore3_package))

      ig = repo.find_or_load('hl7.fhir.us.core#3.1.1')

      expect(ig.id).to eq('hl7.fhir.us.core#3.1.1')
      expected_package_path = File.join(temp_package_cache, 'hl7.fhir.us.core#3.1.1')
      expect(ig.source_path).to eq(expected_package_path)
      expect_spot_check_uscore3(ig)
    end

    it 'finds an in-memory IG by ID' do
      sampleig = Inferno::Entities::IG.new(id: 'sampleig')
      sampleig.add_self_to_repository

      ig = repo.find_or_load('sampleig')
      expect(ig).to be(sampleig)
    end

    it 'finds an in-memory IG by filename' do
      sampleig2 = Inferno::Entities::IG.new(id: 'sampleig2', source_path: '/home/ig/package123.tgz')
      sampleig2.add_self_to_repository

      ig = repo.find_or_load('/home/ig/package123.tgz')
      expect(ig).to be(sampleig2)
    end
  end
end
