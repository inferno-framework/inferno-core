require 'fileutils'

Inferno::Application.register_provider(:ig_files) do
  prepare do
    # This process should only run once, to start one job per validator,
    # so skipping it on workers will start it only once from the "web" process
    next if Sidekiq.server?

    target_container.start :logging

    test_kit_gems = Bundler.definition.specs.select { |spec| spec.metadata['inferno_test_kit']&.casecmp? 'true' }

    ig_files = test_kit_gems.flat_map do |test_kit|
      Dir.glob(File.join(test_kit.full_gem_path, 'lib', '*', 'igs', '*.tgz'))
    end

    if test_kit_gems.none? { |gem| gem.full_gem_path == Dir.pwd }
      ig_files += Dir.glob(File.join(Dir.pwd, 'lib', '*', 'igs', '*.tgz'))
    end

    if File.exist? File.join(Dir.pwd, 'data', 'igs')
      ig_files.each do |source_file_path|
        destination_file_path = File.join(Dir.pwd, 'data', 'igs', File.basename(source_file_path))
        Inferno::Application['logger'].info("Copying #{File.basename(source_file_path)} to data/igs")
        FileUtils.copy_file(source_file_path, destination_file_path, true)
      end
    end
  end
end
