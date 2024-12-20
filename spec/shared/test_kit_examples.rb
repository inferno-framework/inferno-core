Rspec.shared_examples 'deployable_test_kit' do
  describe 'TestKit' do
    let(:test_kit_location) do
      Object.const_source_location(described_class.name)
    end
    let(:test_kit_gem) do
      Bundler.definition.specs.find { |gem| test_kit_location.start_with? gem.full_gem_path }
    end
    let(:base_path) { test_git_gem.full_gem_path }
    let(:test_kit) { described_class.const_get('Metadata') }

    it 'defines test kit in the Metadata class' do
      error_message = <<~MESSAGE
        Define #{described_class.name}::Metadata at
        lib/#{described_class.name.underscore}/metadata.rb and require it in
        lib/#{described_class.name.underscore}.rb
      MESSAGE
      expect { test_kit }.to_not raise(NameError), error_message

      expect(test_kit).to be_a(Inferno::Entities::TestKit)
    end

    it 'relies on the test kit version rather than defining the version in the suites' do
      suites = test_kit.suite_ids.map { |id| Inferno::Repositories::TestSuites.new.find(id) }
      suite_paths = suites.map { |suite| Object.const_source_location(suite.name) }
      suite_contents = suite_paths.map { |path| File.read(path) }

      suite_contents.each_with_index do |suite, i|
        error_message = <<~MESSAGE
          Suite at #{suite_paths[i]} should not explicitly declare a version, as
          its version can now be determined by the version of its Test Kit.
          Remove the `version` method call in the suite definition.
        MESSAGE

        expect(suite).to_not match(%r{^\s+version(\s|\()\S+\)?}), error_message
      end
    end

    it 'defines all required fields' do
      required_fields = [
        :id,
        :title,
        :description,
        :suite_ids,
        :version,
        :maturity
      ]

      required_fields.each do |field_name|
        expect(test_kit).send(field_name).to be_present
      end
    end

    it 'has a description with a <!-- break -->' do
      error_message = <<~MESSAGE
        The test kit description must begin with one paragraph followed by "<!--
        break -->". The portion of the description above the break is displayed
        on the test kit listing page.
      MESSAGE

      expect(test_kit.description).to include('<!-- break -->'), error_message
    end

    it 'has a maturity of "Low", "Medium", or "High"' do
      expect(['Low', 'Medium', 'High']).to include(test_kit.maturity)
    end
  end

  describe 'presets' do
    it 'includes presets in the gem' do
      presets = Dir[
        File.join(base_path, 'config', 'presets', '*.json'),
        File.join(base_path, 'config', 'presets', '*.json.erb')
      ]

      expect(test_kit_gem.files).to include(*presets)
    end
  end

  describe 'gemspec' do
    it 'uses git to determine files to include in the gem' do
      gemspec_contents = File.read(File.join(base_path, "#{test_kit_gem.name}.gemspec"))

      error_message = <<~MESSAGE
        Use git to determine which files to include in the gem. In
        #{test_kit_gem.name}.gemspec, use:
        spec.files = `[ -d .git ] && git ls-files -z lib config/presets LICENSE`.split("\x0")
      MESSAGE

      expect(gemspec_contents).to include('[ -d .git ] && git ls-files'), error_message
    end
  end
end
