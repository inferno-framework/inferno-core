require_relative '../../repositories/presets'

Inferno::Application.register_provider(:presets) do
  prepare do
    target_container.start :suites

    presets_repo = Inferno::Repositories::Presets.new

    test_kit_gems =
      Bundler
        .definition
        .specs
        .select { |spec| spec.metadata.fetch('inferno_test_kit', 'false').casecmp? 'true' }

    files_to_load = Dir.glob(['config/presets/*.json', 'config/presets/*.json.erb'])
    files_to_load +=
      test_kit_gems.flat_map do |gem|
        [
          Dir.glob([File.join(gem.full_gem_path, 'config', 'presets', '*.json')]),
          Dir.glob([File.join(gem.full_gem_path, 'config', 'presets', '*.json.erb')])
        ].flatten
      end

    files_to_load.compact!
    files_to_load.map! { |path| File.realpath(path) }
    files_to_load.uniq!

    files_to_load.each do |path|
      presets_repo.insert_from_file(path)
    end
  end
end
