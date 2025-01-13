require_relative '../../repositories/requirements'

Inferno::Application.register_provider(:requirements) do
  prepare do
    target_container.start :suites

    requirements_repo = Inferno::Repositories::Requirements.new

    test_kit_gems =
      Bundler
        .definition
        .specs
        .select { |spec| spec.metadata.fetch('inferno_test_kit', 'false').casecmp? 'true' }

    files_to_load = Dir.glob(['lib/*test_kit/requirements/*.csv'])

    if ENV['LOAD_DEV_SUITES'].present?
      ENV['LOAD_DEV_SUITES'].split(',').map(&:strip).reject(&:empty?).each do |suite|
        files_to_load.concat Dir.glob(File.join(Inferno::Application.root, 'dev_suites', suite, 'requirements',
                                                '*.csv'))
      end
    end

    files_to_load +=
      test_kit_gems.flat_map do |gem|
        [
          Dir.glob([File.join(gem.full_gem_path, 'lib', '*test_kit', 'requirements', '*.csv')])
        ].flatten
      end

    files_to_load.compact!
    files_to_load.uniq!
    files_to_load.map! { |path| File.realpath(path) }

    files_to_load.each do |path|
      requirements_repo.insert_from_file(path)
    end
  end
end
