require 'yaml'

Inferno::Application.register_provider(:test_kits) do
  prepare do
    test_kit_gems =
      Bundler
        .definition
        .specs
        .select { |spec| spec.metadata.fetch('inferno_test_kit', 'false').casecmp? 'true' }

    test_kit_gems.each do |gem|
      test_kit_metadata_path = File.join(gem.full_gem_path, 'lib', gem.name, 'test_kit_metadata.yml')
      test_kit_metadata = YAML.safe_load_file(test_kit_metadata_path)
      Inferno::Entities::TestKit.new(test_kit_metadata).add_self_to_repository
    end
  end
end
