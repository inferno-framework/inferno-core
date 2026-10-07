RSpec.describe Inferno::DSL::ShortIDManager do
  # Each example defines its own suite with a unique id, since runnable ids are
  # registered globally and the short id map is memoized on the class.
  let(:suite_id) { "short_id_manager_spec_suite_#{SecureRandom.hex(4)}" }
  let(:suite) do
    suite_id = self.suite_id
    stub_const(
      'ShortIDManagerSpecSuite',
      Class.new(Inferno::TestSuite) do
        id suite_id

        group do
          id :group_a

          test do
            id :test_a
            run { pass }
          end
        end

        group do
          id :group_b
        end
      end
    )
  end
  let(:descendant_ids) { suite.all_descendants.map(&:id) }

  describe '.short_id_file_name' do
    it 'is based on the class name' do
      expect(suite.short_id_file_name).to eq('short_id_manager_spec_suite_short_id_map.yml')
    end
  end

  describe '.base_short_id_file_folder' do
    it 'returns a folder that contains the short id file' do
      Dir.mktmpdir do |dir|
        nested = File.join(dir, 'nested')
        FileUtils.mkdir_p(nested)
        File.write(File.join(dir, suite.short_id_file_name), '')

        expect(suite.base_short_id_file_folder(nested)).to eq(dir)
      end
    end

    it 'stops at a folder directly inside lib' do
      Dir.mktmpdir do |dir|
        lib_child = File.join(dir, 'lib', 'my_test_kit')
        FileUtils.mkdir_p(File.join(lib_child, 'deeper'))

        expect(suite.base_short_id_file_folder(File.join(lib_child, 'deeper'))).to eq(lib_child)
      end
    end

    it 'stops at the filesystem root' do
      expect(suite.base_short_id_file_folder('/')).to eq('/')
    end
  end

  context 'with a short id file' do
    let(:short_id_dir) { Dir.mktmpdir }
    let(:short_id_file_path) { File.join(short_id_dir, suite.short_id_file_name) }

    before do
      allow(suite).to receive(:short_id_file_path).and_return(short_id_file_path)
    end

    after { FileUtils.remove_entry(short_id_dir) }

    describe '.short_id_map' do
      it 'loads the short id map from the file' do
        File.write(short_id_file_path, YAML.dump(descendant_ids.first => '9.9'))

        expect(suite.short_id_map).to eq(descendant_ids.first => '9.9')
      end
    end

    describe '.assign_short_ids' do
      it 'assigns short ids from the map and warns about runnables missing from it' do
        mapped_ids = descendant_ids.first(2)
        unmapped_ids = descendant_ids.drop(2)
        File.write(short_id_file_path, YAML.dump(mapped_ids.zip(['7', '7.1']).to_h))
        allow(Inferno::Application['logger']).to receive(:warn)

        suite.assign_short_ids

        expect(suite.all_descendants.first(2).map(&:short_id)).to eq(['7', '7.1'])
        unmapped_ids.each do |unmapped_id|
          expect(Inferno::Application['logger']).to have_received(:warn).with("No short id defined for #{unmapped_id}")
        end
      end
    end
  end

  context 'without a short id file' do
    before do
      allow(suite).to receive(:short_id_file_path).and_return('/does/not/exist/short_id_map.yml')
    end

    it 'has no short id map' do
      expect(suite.short_id_map).to be_nil
    end

    it 'leaves short ids unchanged when assigning short ids' do
      original_short_ids = suite.all_descendants.map(&:short_id)

      suite.assign_short_ids

      expect(suite.all_descendants.map(&:short_id)).to eq(original_short_ids)
    end
  end

  describe '.current_short_id_map' do
    it 'maps each descendant id to its current short id' do
      expected_map = suite.all_descendants.to_h { |runnable| [runnable.id, runnable.short_id] }

      expect(suite.current_short_id_map).to eq(expected_map)
    end
  end
end
