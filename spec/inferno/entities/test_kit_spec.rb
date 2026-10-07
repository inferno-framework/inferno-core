RSpec.describe Inferno::Entities::TestKit do
  let(:test_kit) do
    Class.new(described_class) do
      id :spec_example_test_kit
      title 'Spec Example Test Kit'
      description 'A test kit used in specs.'
      tags ['SMART App Launch', 'US Core']
      last_updated '2026-01-01'
      version '1.2.3'
      maturity 'Low'
      suite_ids [:demo, 'options']
      repo 'https://github.com/inferno-framework/example-test-kit'
      authors ['Author One', 'Author Two']
    end
  end

  describe 'metadata' do
    it 'returns the values that were set' do
      expect(test_kit.id).to eq(:spec_example_test_kit)
      expect(test_kit.title).to eq('Spec Example Test Kit')
      expect(test_kit.description).to eq('A test kit used in specs.')
      expect(test_kit.tags).to eq(['SMART App Launch', 'US Core'])
      expect(test_kit.last_updated).to eq('2026-01-01')
      expect(test_kit.version).to eq('1.2.3')
      expect(test_kit.maturity).to eq('Low')
      expect(test_kit.suite_ids).to eq([:demo, 'options'])
      expect(test_kit.repo).to eq('https://github.com/inferno-framework/example-test-kit')
      expect(test_kit.authors).to eq(['Author One', 'Author Two'])
    end

    it 'defaults suite_ids to an empty array' do
      expect(Class.new(described_class).suite_ids).to eq([])
    end
  end

  describe '.suites' do
    it 'returns the suites for the suite ids' do
      expect(test_kit.suites.map(&:id)).to eq(['demo', 'options'])
    end

    it 'memoizes the suites' do
      first_call = test_kit.suites

      expect(test_kit.suites).to be(first_call)
    end
  end

  describe '.options' do
    it 'returns the suite options keyed by suite id' do
      options = test_kit.options

      expect(options.keys).to eq(['demo', 'options'])
      expect(options['options'].map(&:id)).to include(:ig_version, :other_option)
    end

    it 'memoizes the options' do
      first_call = test_kit.options

      expect(test_kit.options).to be(first_call)
    end
  end

  describe '.contains_test_suite?' do
    it 'returns true for a suite id in the test kit, whether given as a string or symbol' do
      expect(test_kit.contains_test_suite?('demo')).to be(true)
      expect(test_kit.contains_test_suite?(:options)).to be(true)
    end

    it 'returns false for a suite id not in the test kit' do
      expect(test_kit.contains_test_suite?('other_suite')).to be(false)
    end
  end

  describe '.url_fragment' do
    it 'removes the _test_kit suffix from the id' do
      expect(test_kit.url_fragment).to eq('spec_example')
    end

    it 'leaves an id without the suffix unchanged' do
      test_kit.id :spec_example

      expect(test_kit.url_fragment).to eq('spec_example')
    end
  end

  describe '.add_self_to_repository' do
    it 'inserts the test kit into the test kit repository' do
      repository = instance_double(Inferno::Repositories::TestKits, insert: nil)
      allow(Inferno::Repositories::TestKits).to receive(:new).and_return(repository)

      test_kit.add_self_to_repository

      expect(repository).to have_received(:insert).with(test_kit)
    end
  end
end
