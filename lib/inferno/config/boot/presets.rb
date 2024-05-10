require_relative '../../repositories/presets'

Inferno::Application.register_provider(:presets) do
  prepare do
    target_container.start :suites

    files_to_load = Dir.glob(['config/presets/*.json', 'config/presets/*.json.erb'])
    files_to_load.map! { |path| File.realpath(path) }
    presets_repo = Inferno::Repositories::Presets.new

    files_to_load.each do |path|
      presets_repo.insert_from_file(path)
    end
  end
end
