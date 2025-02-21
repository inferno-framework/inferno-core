require 'fileutils'

Inferno::Application.register_provider(:ig_files) do
  prepare do
    # This process should only run once, so skipping it on workers will start it
    # only once from the "web" process
    next if Sidekiq.server?

    target_container.start :logging

    test_kit_gems = Bundler.definition.specs.select { |spec| spec.metadata['inferno_test_kit']&.casecmp? 'true' }

    test_kit_ig_files = test_kit_gems.map do |test_kit|
      files = Dir.glob(File.join(test_kit.full_gem_path, 'lib', '*', 'igs', '*.tgz'))
      next if files.blank?

      {
        test_kit_name: test_kit.name,
        files:
      }
    end.compact

    local_ig_files = Dir.glob(File.join(Dir.pwd, 'lib', '*', 'igs', '*.tgz'))

    if local_ig_files.present? && test_kit_gems.none? { |gem| gem.full_gem_path == Dir.pwd }
      test_kit_ig_files += {
        test_kit_name: 'current project',
        files: local_ig_files
      }
    end

    if File.exist? File.join(Dir.pwd, 'data', 'igs')
      test_kit_ig_files.each do |ig_files|
        ig_files[:files].each do |source_file_path|
          destination_file_path = File.join(Dir.pwd, 'data', 'igs', File.basename(source_file_path))
          Inferno::Application['logger'].info(
            "Copying #{File.basename(source_file_path)} to data/igs from #{ig_files[:test_kit_name]}"
          )
          FileUtils.copy_file(source_file_path, destination_file_path, true)
        end
      end
    end
  end
end
